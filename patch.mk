PATCH_FILE ?= $(PROJECT_ROOT)/$(NAME).patch
PATCH_ID := $(shell cd $(QNX_PROJECT_ROOT); git patch-id < $(PATCH_FILE) | cut -d' ' -f1)
PATCH_FLAG := $(PROJECT_ROOT)/.patched_$(PATCH_ID)
BACKUP_DIR := $(PROJECT_ROOT)/patch_backups

apply-patch: check-patch-status
	@if [ ! -f $(PATCH_FLAG) ]; then \
		echo "Apply patch: $(PATCH_FILE)"; \
		mkdir -p $(BACKUP_DIR); \
		cd $(QNX_PROJECT_ROOT); git apply --numstat $(PATCH_FILE) | awk '{print $$3}' | \
			while IFS= read -r file; do \
				[ -n "$$file" ] && cp --parents -v "$$file" $(BACKUP_DIR); \
			done; \
		cd $(QNX_PROJECT_ROOT); git apply $(PATCH_FILE); \
		touch $(PATCH_FLAG); \
	fi

check-patch-status:
	@( \
	if [ -f $(PATCH_FLAG) ]; then \
		echo "Patch already applied [ID: $(shell echo $(PATCH_ID) | cut -c1-8)...]"; \
		exit 0; \
	fi; \
	if (cd $(QNX_PROJECT_ROOT); git apply --reverse --check $(PATCH_FILE) >/dev/null 2>&1); then \
		echo "Patch already applied [ID: $(shell echo $(PATCH_ID) | cut -c1-8)...]"; \
		touch $(PATCH_FLAG); \
		exit 0; \
	fi; \
	if ! (cd $(QNX_PROJECT_ROOT); git apply --check $(PATCH_FILE) >/dev/null 2>&1); then \
		echo "Patch check failed, possible conflict"; \
		exit 1; \
	fi \
	)

revert-patch:
	@if [ -f $(PATCH_FLAG) ]; then \
		echo "Revert patch: $(PATCH_FILE)"; \
		cd $(QNX_PROJECT_ROOT); git apply -R $(PATCH_FILE); \
		rm -f $(PATCH_FLAG); \
	else \
		if (cd $(QNX_PROJECT_ROOT); git apply --reverse --check $(PATCH_FILE) >/dev/null 2>&1); then \
			echo "Revert patch: $(PATCH_FILE)"; \
			cd $(QNX_PROJECT_ROOT); git apply -R $(PATCH_FILE); \
		else \
			echo "No patch to revert."; \
		fi \
	fi

restore-backup:
	@if [ -d $(BACKUP_DIR) ]; then \
		echo "Restore from backup files"; \
		cp -ri $(BACKUP_DIR)/* ./; \
	else \
		echo "Can not find backup folder: $(BACKUP_DIR)"; \
	fi

clean-patch: revert-patch
	@rm -f .patched_*
	@rm -rf $(BACKUP_DIR)

patch-info:
	@echo "Patch file: $(PATCH_FILE)"
	@echo "Patch ID: $(PATCH_ID)"
	@echo "Status: $(shell if [ -f $(PATCH_FLAG) ]; then echo "Applied"; else echo "Not applied"; fi)"
	@echo "Backup folder: $(BACKUP_DIR)"
	@cd $(QNX_PROJECT_ROOT); git apply --numstat $(PATCH_FILE) | head -n 5

.PHONY: apply-patch check-patch-status revert-patch restore-backup clean-patch patch-info
