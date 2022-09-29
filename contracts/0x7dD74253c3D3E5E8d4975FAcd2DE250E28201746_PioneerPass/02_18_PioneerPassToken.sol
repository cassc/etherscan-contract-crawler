// SPDX-License-Identifier: MIT
// Creator: @casareafer at 1TM.io

pragma solidity ^0.8.17;

import "./openzeppelin/ERC1155.sol";
import "./openzeppelin/Ownable.sol";
import "./PioneerPassLibrary.sol";
import "./PioneerPassStorage.sol";
import "./PioneerPassUtils.sol";
import "./ContractURI.sol";
import "./Staking.sol";

contract PioneerPassToken is ERC1155, Ownable, PioneerPassStorage, ContractURI, Stacking, PioneerPassUtils {
    address private royaltiesTeamWallet;
    mapping(uint256 => bool) private transfersLock;

    constructor(string memory _contractURI, address _royaltyAddress){
        _setContractURI(_contractURI);
        royaltiesTeamWallet = _royaltyAddress;
    }

    /**
    *   Pause control
    */

    function setTransfersLock(uint256 _passId, bool _value) external onlyOwner {
        transfersLock[_passId] = _value;
    }

    /**
    *   Royalties - EIP2981
    */

    function royaltyInfo(uint256 _passId, uint256 _salePrice) external view
    returns (address receiver, uint256 royaltyAmount)
    {
        if (_passId == 1) {
            return (royaltiesTeamWallet, _salePrice * 80 / 1000);
        } else
        {
            return (royaltiesTeamWallet, _salePrice * 50 / 1000);
        }
    }

    function setRoyaltyAddress(address _teamWallet) external onlyOwner {
        royaltiesTeamWallet = _teamWallet;
    }

    /**
    *   Burn implementation
    */

    function burn(
        address from,
        uint id,
        uint256 amount
    ) external {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not token owner nor approved"
        );
        _burn(from, id, amount);
    }

    /**
    *   Token & Contract metadata
    */

    function setContractURI(string memory _contractURI) external onlyOwner {
        _setContractURI(_contractURI);
    }

    function setUri(uint256 _tokenId, string memory _tokenURI) external onlyOwner {
        _tokenURIs[_tokenId] = _tokenURI;
    }

    function uri(uint256 _passId)
    external
    view
    override
    returns (string memory)
    {
        require(passIdToCollectionPass[_passId].passId != 0, "Invalid pass");
        return string(
            abi.encodePacked(_baseURI, _tokenURIs[_passId])
        );
    }

    /**
    *   Withdraw
    */

    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    /**
    *   Stacking & Transfers lock require these overrides
    */

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override(ERC1155) {
        for (uint bar = 0; bar < ids.length; bar++) {
            require(!transfersLock[ids[bar]], "Transfers locked");
        }
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    function _afterTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override(ERC1155) {
        super._afterTokenTransfer(operator, from, to, ids, amounts, data);
        Stacking.stakeTransfer(ids, amounts, to, from);
    }
}