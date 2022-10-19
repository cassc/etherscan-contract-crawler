// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "../../interfaces/ICNR.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract NFT is ERC721, AccessControl {
    using Counters for Counters.Counter;
    Counters.Counter tokenIdCounterProducer;
    Counters.Counter tokenIdCounterFod;

    uint256 public totalSupply;

    ICNR CNR;

    constructor(ICNR _CNR, address _default_admin_role) ERC721("Corite x 1001Tracklists 2022", "CO-FoD") {
        _setupRole(DEFAULT_ADMIN_ROLE, _default_admin_role);
        CNR = _CNR;
    }

    function mintProducers(address _to, uint256 _amount)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(_amount <= 101, "Can only mint 101 nfts");
        require(_amount != 0, "Can't mint 0 nfts");
        for (uint256 i = 0; i < _amount; i++) {
            tokenIdCounterProducer.increment();
            totalSupply++;
            _safeMint(_to, tokenIdCounterProducer.current());
        }
    }

    function mintFoD(address _to, uint256 _amount)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(_amount <= 101, "Can only mint 101 nfts");
        require(_amount != 0, "Can't mint 0 nfts");
        for (uint256 i = 0; i < _amount; i++) {
            tokenIdCounterFod.increment();
            totalSupply++;
            _safeMint(_to, tokenIdCounterFod.current() + 1000);
        }
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(
            _exists(_tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        return ICNR(CNR).getNFTURI(address(this), _tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}