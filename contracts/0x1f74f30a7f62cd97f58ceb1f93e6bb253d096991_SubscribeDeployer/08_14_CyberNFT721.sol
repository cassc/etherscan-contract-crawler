// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import { ERC721 } from "../dependencies/solmate/ERC721.sol";
import { Initializable } from "openzeppelin-contracts/contracts/proxy/utils/Initializable.sol";

import { ICyberNFT721 } from "../interfaces/ICyberNFT721.sol";

/**
 * @title Cyber 721 NFT Base
 * @author CyberConnect
 * @notice This contract is the base for all 721 NFT contracts.
 */
abstract contract CyberNFT721 is ERC721, ICyberNFT721 {
    /*//////////////////////////////////////////////////////////////
                                STATES
    //////////////////////////////////////////////////////////////*/
    uint256 internal _currentIndex;
    uint256 internal _totalSupply;

    /*//////////////////////////////////////////////////////////////
                                 CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor() {
        _disableInitializers();
    }

    /*//////////////////////////////////////////////////////////////
                         EXTERNAL VIEW
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc ICyberNFT721
    function totalSupply() external view virtual override returns (uint256) {
        return _totalSupply;
    }

    /*//////////////////////////////////////////////////////////////
                                 PUBLIC
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc ICyberNFT721
    function burn(uint256 tokenId) public virtual override {
        address owner = ownerOf(tokenId);
        require(
            msg.sender == owner ||
                msg.sender == getApproved[tokenId] ||
                isApprovedForAll[owner][msg.sender],
            "NOT_OWNER_OR_APPROVED"
        );
        super._burn(tokenId);
        _totalSupply--;
    }

    /*//////////////////////////////////////////////////////////////
                              INTERNAL
    //////////////////////////////////////////////////////////////*/

    function _initialize(
        string calldata name,
        string calldata symbol
    ) internal onlyInitializing {
        ERC721.__ERC721_Init(name, symbol);
    }

    function _mint(address _to) internal virtual returns (uint256) {
        uint256 mintedId = _currentIndex;
        super._safeMint(_to, mintedId);

        _currentIndex++;
        _totalSupply++;

        return mintedId;
    }

    function _exists(uint256 tokenId) internal view returns (bool) {
        return _ownerOf[tokenId] != address(0);
    }

    function _requireMinted(uint256 tokenId) internal view virtual {
        require(_exists(tokenId), "NOT_MINTED");
    }
}