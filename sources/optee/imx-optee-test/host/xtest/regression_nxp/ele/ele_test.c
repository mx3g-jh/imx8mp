// SPDX-License-Identifier: BSD-2-Clause
/*
 * Copyright 2023 NXP
 */

#include <err.h>
#include <pta_ele_test.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <tee_client_api.h>
#include <tee_client_api_extensions.h>
#include <utee_defines.h>
#include <util.h>

#include "xtest_helpers.h"
#include "xtest_test.h"

static void nxp_crypto_0023(ADBG_Case_t *const c)
{
	TEEC_Result res = TEEC_ERROR_GENERIC;
	TEEC_Session sess = {};
	TEEC_UUID uuid = PTA_ELE_TEST_UUID;
	uint32_t err_origin = 0;
	TEEC_Operation op = TEEC_OPERATION_INITIALIZER;

	op.paramTypes = TEEC_PARAM_TYPES(TEEC_NONE, TEEC_NONE,
					 TEEC_NONE, TEEC_NONE);

	res = xtest_teec_open_session(&sess, &uuid, NULL, &err_origin);
	if (res == TEEC_ERROR_ITEM_NOT_FOUND) {
		Do_ADBG_Log("Skip test, ELE Test PTA not found");
		return;
	}

	if (!ADBG_EXPECT_TEEC_SUCCESS(c, res)) {
		Do_ADBG_Log("Failed to open ELE Test PTA ");
		return;
	}

	Do_ADBG_BeginSubCase(c, "Generate/Delete Key with Sign/Verify");

	res = TEEC_InvokeCommand(&sess, PTA_ELE_CMD_TEST_SIGN_VERIFY,
				 &op, &err_origin);
	if (!ADBG_EXPECT_TEEC_SUCCESS(c, res))
		goto out;

	Do_ADBG_EndSubCase(c, "Generate/Delete Key with Sign/Verify");

out:
	TEEC_CloseSession(&sess);
}

ADBG_CASE_DEFINE(regression_nxp, 0023, nxp_crypto_0023,
		 "ELE ECC Key Generation/Deletion with sign/verify ");

static void nxp_crypto_0022(ADBG_Case_t *const c)
{
	TEEC_Result res = TEEC_ERROR_GENERIC;
	TEEC_Session sess = {};
	TEEC_UUID uuid = PTA_ELE_TEST_UUID;
	uint32_t err_origin = 0;
	TEEC_Operation op = TEEC_OPERATION_INITIALIZER;

	op.paramTypes = TEEC_PARAM_TYPES(TEEC_NONE, TEEC_NONE,
					 TEEC_NONE, TEEC_NONE);

	res = xtest_teec_open_session(&sess, &uuid, NULL, &err_origin);
	if (res == TEEC_ERROR_ITEM_NOT_FOUND) {
		Do_ADBG_Log("Skip test, ELE Test PTA not found");
		return;
	}

	if (!ADBG_EXPECT_TEEC_SUCCESS(c, res)) {
		Do_ADBG_Log("Failed to open ELE Test PTA ");
		return;
	}

	Do_ADBG_BeginSubCase(c, "Generate Key/Delete Key");

	res = TEEC_InvokeCommand(&sess, PTA_ELE_CMD_TEST_KEY_GENERATE_DELETE,
				 &op, &err_origin);
	if (!ADBG_EXPECT_TEEC_SUCCESS(c, res))
		goto out;

	Do_ADBG_EndSubCase(c, "Generate Key/Delete Key");

out:
	TEEC_CloseSession(&sess);
}

ADBG_CASE_DEFINE(regression_nxp, 0022, nxp_crypto_0022,
		 "ELE ECC Key Generation/Deletion ");
