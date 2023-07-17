// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.8;

import "lib/ERC721A-Upgradeable/contracts/IERC721AUpgradeable.sol";

interface IVNFT is IERC721AUpgradeable {
    function activeNfts() external view returns (uint256[] memory);

    /**
     * @notice Returns the validators that are active (may contain validator that are yet active on beacon chain)
     */
    function activeValidatorsOfStakingPool() external view returns (bytes[] memory);

    /**
     * @notice Returns the tokenId that are active (may contain validator that are yet active on beacon chain)
     */
    function activeNftsOfStakingPool() external view returns (uint256[] memory);

    /**
     * @notice get empty nft counts
     */
    function getEmptyNftCounts() external view returns (uint256);

    /**
     * @notice Checks if a validator exists
     * @param _pubkey - A 48 bytes representing the validator's public key
     */
    function validatorExists(bytes calldata _pubkey) external view returns (bool);

    /**
     * @notice Finds the validator's public key of a nft
     * @param _tokenId - tokenId of the validator nft
     */
    function validatorOf(uint256 _tokenId) external view returns (bytes memory);

    /**
     * @notice Finds all the validator's public key of a particular address
     * @param _owner - The particular address
     */
    function validatorsOfOwner(address _owner) external view returns (bytes[] memory);

    /**
     * @notice Finds the operator id of a nft
     * @param _tokenId - tokenId of the validator nft
     */
    function operatorOf(uint256 _tokenId) external view returns (uint256);

    /**
     * @notice Get the number of operator's active nft
     * @param _operatorId - operator id
     */
    function getActiveNftCountsOfOperator(uint256 _operatorId) external view returns (uint256);

    /**
     * @notice Get the number of operator's empty nft
     * @param _operatorId - operator id
     */
    function getEmptyNftCountsOfOperator(uint256 _operatorId) external view returns (uint256);

    /**
     * @notice Get the number of user's active nft
     * @param _operatorId - operator id
     */
    function getUserActiveNftCountsOfOperator(uint256 _operatorId) external view returns (uint256);

    /**
     * @notice Finds the tokenId of a validator
     * @dev Returns MAX_SUPPLY if not found
     * @param _pubkey - A 48 bytes representing the validator's public key
     */
    function tokenOfValidator(bytes calldata _pubkey) external view returns (uint256);

    /**
     * @notice Returns the last owner before the nft is burned
     * @param _tokenId - tokenId of the validator nft
     */
    function lastOwnerOf(uint256 _tokenId) external view returns (address);

    /**
     * @notice Mints a Validator nft (vNFT)
     * @param _pubkey -  A 48 bytes representing the validator's public key
     * @param _to - The recipient of the nft
     * @param _operatorId - The operator repsonsible for operating the physical node
     */
    function whiteListMint(
        bytes calldata _pubkey,
        bytes calldata _withdrawalCredentials,
        address _to,
        uint256 _operatorId
    ) external returns (uint256);

    /**
     * @notice Burns a Validator nft (vNFT)
     * @param _tokenId - tokenId of the validator nft
     */
    function whiteListBurn(uint256 _tokenId) external;

    /**
     * @notice Obtain the withdrawal voucher used by tokenid,
     * if it is bytes(""), it means it is not the user's nft, and the voucher will be the withdrawal contract address of the nodedao protocol
     * @param _tokenId - tokenId
     */
    function getUserNftWithdrawalCredentialOfTokenId(uint256 _tokenId) external view returns (bytes memory);

    /**
     * @notice The operator obtains the withdrawal voucher to be used for the next registration of the validator.
     *  // If it is bytes (""), it means that it is not the user's NFT, and the voucher will be the withdrawal contract address of the nodedao protocol.
     * @param _operatorId - operatorId
     */
    function getNextValidatorWithdrawalCredential(uint256 _operatorId) external view returns (bytes memory);

    /**
     * @notice set nft exit height
     * @param _tokenIds - tokenIds
     * @param _exitBlockNumbers - tokenIds
     */
    function setNftExitBlockNumbers(uint256[] memory _tokenIds, uint256[] memory _exitBlockNumbers) external;

    /**
     * @notice Get the number of nft exit height
     * @param _tokenIds - tokenIds
     */
    function getNftExitBlockNumbers(uint256[] memory _tokenIds) external view returns (uint256[] memory);

    /**
     * @notice set nft gas height
     * @param _tokenId - tokenId
     * @param _number - gas height
     */
    function setUserNftGasHeight(uint256 _tokenId, uint256 _number) external;

    /**
     * @notice Get the number of user's nft gas height
     * @param _tokenIds - tokenIds
     */
    function getUserNftGasHeight(uint256[] memory _tokenIds) external view returns (uint256[] memory);

    /**
     * @notice Get the number of total active nft counts
     */
    function getTotalActiveNftCounts() external view returns (uint256);
}