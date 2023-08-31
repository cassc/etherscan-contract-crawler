// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.16;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

/**
 * @title IVerifiedSBT
 * @notice VerifiedSBT is an SBT token contract whose token mint is allowed to contract verifier
 */
interface IVerifiedSBT {
    /**
     * @notice Function for initialization of the initial contract state
     * @param verifier_ the address of the verifier contract
     * @param name_ the SBT token name
     * @param symbol_ the SBT token symbol
     * @param tokensURI_ the tokens URI string
     */
    function __VerifiedSBT_init(
        address verifier_,
        string memory name_,
        string memory symbol_,
        string memory tokensURI_
    ) external;

    /**
     * @notice Function for updating the address of the verifier's contract
     * @dev Only contract OWNER can call this function
     * @param newVerifier_ the new verifier contract address
     */
    function setVerifier(address newVerifier_) external;

    /**
     * @notice Function for updating the tokens URI string
     * @dev Only contract OWNER can call this function
     * @param newTokensURI_ the new tokens URI string
     */
    function setTokensURI(string calldata newTokensURI_) external;

    /**
     * @notice Function for minting new tokens
     * @dev Only verifier contract can call this function
     * @param recipientAddr_ the address of the token recipient
     */
    function mint(address recipientAddr_) external;

    /**
     * @notice Function that returns the verifier contract address
     * @return The verifier contract address
     */
    function verifier() external view returns (address);

    /**
     * @notice Function that returns the next token ID
     * @return The next token ID
     */
    function nextTokenId() external view returns (uint256);

    /**
     * @notice Function that returns the tokens URI string
     * @return The tokens URI string
     */
    function tokensURI() external view returns (string memory);
}