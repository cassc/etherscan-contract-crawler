// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

interface IOwnershipHolder {
    // ----- PROXY METHODS ----- //
    function pEditClaimingAddress(
        address _contractAddress,
        address _newAddress
    ) external;

    function pEditRoyaltyFee(
        address _contractAddress,
        uint256 _newFee
    ) external;

    function pEditTokenUri(
        address _contractAddress,
        string memory _ttokenUri
    ) external;

    function pRecoverERC20(address _contractAddress, address token) external;

    function pOwner(address _contractAddress) external view returns (address);

    function pTransferOwnership(
        address _contractAddress,
        address newOwner
    ) external;

    function pBatchMintSelectedIds(
        uint256[] memory _ids,
        address[] memory _addresses,
        address _contractAddress
    ) external;

    function pMintNFTTokens(
        address _contractAddress,
        address _requesterAddress,
        uint256 _bundleId,
        uint256[] memory _tokenIds,
        uint256 _chainId,
        bytes memory _transactionHash
    ) external;

    function pMintNextToken(
        address _contractAddress,
        address _receiver
    ) external;

    function pSetNewPaymentProxy(
        address _contractAddress,
        address _newPP
    ) external;

    function pSetNewAdministrator(
        address _contractAddress,
        address _newAdmin
    ) external;

    function pEditClaimingAdress(
        address _contractAddress,
        address _newAddress
    ) external;

    function pBurn(address _contractAddress, uint256 _tokenId) external;

    function pBatchMintAndBurn1155(
        address _contractAddress,
        uint256[] memory _ids,
        uint256[] memory _amounts,
        bool[] memory _burn,
        address _receiver
    ) external;

    function pBatchBurnFrom1155(
        address _contractAddress,
        uint256[] memory _ids,
        uint256[] memory _amounts,
        address burner
    ) external;
}