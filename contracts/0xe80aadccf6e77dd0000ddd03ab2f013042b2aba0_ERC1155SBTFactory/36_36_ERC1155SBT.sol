// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@thirdweb-dev/contracts/extension/LazyMint.sol";
import "@thirdweb-dev/contracts/extension/Drop1155.sol";
import "@thirdweb-dev/contracts/base/ERC1155Base.sol";
import "@thirdweb-dev/contracts/lib/CurrencyTransferLib.sol";

contract ERC1155SBT is ERC1155Base, Drop1155 {
    address public contractOperator;
    constructor(
        string memory _name,
        string memory _symbol,
        address _royaltyRecipient,
        uint128 _royaltyBps,
        address _owner,
        address _operator
    )
        ERC1155Base(
            _name,
            _symbol,
            _royaltyRecipient,
            _royaltyBps
        )
    {
        contractOperator = _operator;
        _setupOwner(_owner);
    }


    //////////// ContractOperator ////////////
    function _setContractOperator(address _contractOperator) external onlyContractOperator {
        contractOperator = _contractOperator;
    }

    modifier onlyContractOperator() {
        if (msg.sender != contractOperator) {
            revert("Not authorized");
        }
        _;
    }
    //////////// ContractOperator ////////////



    //////////// Impl ////////////
    /// @dev Runs before every `claim` function call.
    function _beforeClaim(
        uint256 ,
        address _receiver,
        uint256 ,
        address ,
        uint256 ,
        AllowlistProof calldata ,
        bytes memory 
    ) pure internal override {
        require(_receiver != address(0), "Receiver must not 0x000.....");
    }

    /// @dev Runs after every `claim` function call.
    function _afterClaim(
        uint256,
        address _receiver,
        uint256,
        address,
        uint256,
        AllowlistProof calldata,
        bytes memory
    ) internal pure override {
        require(_receiver != address(0), "Receiver must not 0x000.....");
    }

    /// @dev Collects and distributes the primary sale value of NFTs being claimed.
    function collectPriceOnClaim(
        uint256,
        address,
        uint256 _quantityToClaim,
        address _currency,
        uint256 _pricePerToken
    ) internal virtual override {
        if (_pricePerToken == 0) {
            return;
        }

        uint256 totalPrice = _quantityToClaim * _pricePerToken;

        if (_currency == CurrencyTransferLib.NATIVE_TOKEN) {
            if (msg.value != totalPrice) {
                revert("Must send total price.");
            }
        }

        CurrencyTransferLib.transferCurrency(_currency, msg.sender, owner(), totalPrice);
    }

    /// @dev Transfers the tokens being claimed.
    function transferTokensOnClaim(
        address _to,
        uint256 _tokenId,
        uint256 _quantityBeingClaimed
    ) internal virtual override
    {
        _mint(_to, _tokenId, _quantityBeingClaimed, "");
    }
    //////////// Impl ////////////



    //////////// Permissions ////////////
    function _canSetContractURI() internal view virtual override returns (bool) {
        return msg.sender == owner() || msg.sender == contractOperator;
    }
    function _canSetOwner() internal view virtual override returns (bool) {
        return msg.sender == owner() || msg.sender == contractOperator;
    }
    function _canMint() internal view virtual override returns (bool) {
        return msg.sender == owner() || msg.sender == contractOperator;
    }
    function _canSetClaimConditions() internal view virtual override returns (bool)
    {
        return msg.sender == owner() || msg.sender == contractOperator;
    }

    //////////// Permissions ////////////


    //////////// SBT Function ////////////
    function setApprovalForAll(address operator, bool approved)
        public
        virtual
        override(ERC1155Base)
        onlyAllowedOperatorApproval(operator)
    {
        require(
            msg.sender == address(0), 
            "Nobady can list the SBT on marketplace"
        );
        super.setApprovalForAll(operator, approved);
    }
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override {
        require(
            from == address(0) || to == address(0), 
            "Cannot send to any one because they are SBTs"
        );
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }
    //////////// SBT Function ////////////
}