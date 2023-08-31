// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

uint256 constant Bytes1_shift = 0xf8;
uint256 constant Bytes4_shift = 0xe0;
uint256 constant Bytes20_shift = 0x60;
uint256 constant One_word = 0x20;

uint256 constant Memory_pointer = 0x40;

uint256 constant AssetType_ERC721 = 0;
uint256 constant AssetType_ERC1155 = 1;

uint256 constant OrderType_ASK = 0;
uint256 constant OrderType_BID = 1;

uint256 constant Pool_withdrawFrom_selector = 0x9555a94200000000000000000000000000000000000000000000000000000000;
uint256 constant Pool_withdrawFrom_from_offset = 0x04;
uint256 constant Pool_withdrawFrom_to_offset = 0x24;
uint256 constant Pool_withdrawFrom_amount_offset = 0x44;
uint256 constant Pool_withdrawFrom_size = 0x64;

uint256 constant Pool_deposit_selector = 0xf340fa0100000000000000000000000000000000000000000000000000000000;
uint256 constant Pool_deposit_user_offset = 0x04;
uint256 constant Pool_deposit_size = 0x24;

uint256 constant ERC20_transferFrom_selector = 0x23b872dd00000000000000000000000000000000000000000000000000000000;
uint256 constant ERC721_safeTransferFrom_selector = 0x42842e0e00000000000000000000000000000000000000000000000000000000;
uint256 constant ERC1155_safeTransferFrom_selector = 0xf242432a00000000000000000000000000000000000000000000000000000000;
uint256 constant ERC20_transferFrom_size = 0x64;
uint256 constant ERC721_safeTransferFrom_size = 0x64;
uint256 constant ERC1155_safeTransferFrom_size = 0xc4;

uint256 constant OracleSignatures_size = 0x59;
uint256 constant OracleSignatures_s_offset = 0x20;
uint256 constant OracleSignatures_v_offset = 0x40;
uint256 constant OracleSignatures_blockNumber_offset = 0x41;
uint256 constant OracleSignatures_oracle_offset = 0x45;

uint256 constant Signatures_size = 0x41;
uint256 constant Signatures_s_offset = 0x20;
uint256 constant Signatures_v_offset = 0x40;

uint256 constant ERC20_transferFrom_from_offset = 0x4;
uint256 constant ERC20_transferFrom_to_offset = 0x24;
uint256 constant ERC20_transferFrom_amount_offset = 0x44;

uint256 constant ERC721_safeTransferFrom_from_offset = 0x4;
uint256 constant ERC721_safeTransferFrom_to_offset = 0x24;
uint256 constant ERC721_safeTransferFrom_id_offset = 0x44;

uint256 constant ERC1155_safeTransferFrom_from_offset = 0x4;
uint256 constant ERC1155_safeTransferFrom_to_offset = 0x24;
uint256 constant ERC1155_safeTransferFrom_id_offset = 0x44;
uint256 constant ERC1155_safeTransferFrom_amount_offset = 0x64;
uint256 constant ERC1155_safeTransferFrom_data_pointer_offset = 0x84;
uint256 constant ERC1155_safeTransferFrom_data_offset = 0xa4;

uint256 constant Delegate_transfer_selector = 0xa1ccb98e00000000000000000000000000000000000000000000000000000000;
uint256 constant Delegate_transfer_calldata_offset = 0x1c;

uint256 constant Order_size = 0x100;
uint256 constant Order_trader_offset = 0x00;
uint256 constant Order_collection_offset = 0x20;
uint256 constant Order_listingsRoot_offset = 0x40;
uint256 constant Order_numberOfListings_offset = 0x60;
uint256 constant Order_expirationTime_offset = 0x80;
uint256 constant Order_assetType_offset = 0xa0;
uint256 constant Order_makerFee_offset = 0xc0;
uint256 constant Order_salt_offset = 0xe0;

uint256 constant Exchange_size = 0x80;
uint256 constant Exchange_askIndex_offset = 0x00;
uint256 constant Exchange_proof_offset = 0x20;
uint256 constant Exchange_maker_offset = 0x40;
uint256 constant Exchange_taker_offset = 0x60;

uint256 constant BidExchange_size = 0x80;
uint256 constant BidExchange_askIndex_offset = 0x00;
uint256 constant BidExchange_proof_offset = 0x20;
uint256 constant BidExchange_maker_offset = 0x40;
uint256 constant BidExchange_taker_offset = 0x60;

uint256 constant Listing_size = 0x80;
uint256 constant Listing_index_offset = 0x00;
uint256 constant Listing_tokenId_offset = 0x20;
uint256 constant Listing_amount_offset = 0x40;
uint256 constant Listing_price_offset = 0x60;

uint256 constant Taker_size = 0x40;
uint256 constant Taker_tokenId_offset = 0x00;
uint256 constant Taker_amount_offset = 0x20;

uint256 constant StateUpdate_size = 0x80;
uint256 constant StateUpdate_salt_offset = 0x20;
uint256 constant StateUpdate_leaf_offset = 0x40;
uint256 constant StateUpdate_value_offset = 0x60;

uint256 constant Transfer_size = 0xa0;
uint256 constant Transfer_trader_offset = 0x00;
uint256 constant Transfer_id_offset = 0x20;
uint256 constant Transfer_amount_offset = 0x40;
uint256 constant Transfer_collection_offset = 0x60;
uint256 constant Transfer_assetType_offset = 0x80;

uint256 constant ExecutionBatch_selector_offset = 0x20;
uint256 constant ExecutionBatch_calldata_offset = 0x40;
uint256 constant ExecutionBatch_base_size = 0xa0; // size of the executionBatch without the flattened dynamic elements
uint256 constant ExecutionBatch_taker_offset = 0x00;
uint256 constant ExecutionBatch_orderType_offset = 0x20;
uint256 constant ExecutionBatch_transfers_pointer_offset = 0x40;
uint256 constant ExecutionBatch_length_offset = 0x60;
uint256 constant ExecutionBatch_transfers_offset = 0x80;