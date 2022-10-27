// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.12;

library GenerativeBoilerplateNFTConfiguration {
    string public constant FEE_TOKEN = "FEE_TOKEN"; // currency using for create project fee
    string public constant CREATE_PROJECT_FEE = "CREATE_PROJECT_FEE"; // fee for user mint project id
    string public constant MINT_NFT_FEE = "MINT_NFT_FEE"; // % will pay for this contract when minter use project id for mint nft
    string public constant GENERATIVE_NFT_TEMPLATE = "GENERATIVE_NFT_TEMPLATE";// address of Generative NFT erc-721 contract
}