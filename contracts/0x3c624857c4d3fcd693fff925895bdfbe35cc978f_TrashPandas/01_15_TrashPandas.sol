// SPDX-License-Identifier: MIT
//
//  @@@@@@@ @@@@@@@   @@@@@@   @@@@@@ @@@  @@@
//    @@!   @@!  @@@ @@!  @@@ [email protected]@     @@!  @@@
//    @!!   @[email protected][email protected]!  @[email protected][email protected][email protected]!  [email protected]@!!  @[email protected][email protected][email protected]!
//    !!:   !!: :!!  !!:  !!!     !:! !!:  !!!
//     :     :   : :  :   : : ::.: :   :   : :
//
//  @@@@@@@   @@@@@@  @@@  @@@ @@@@@@@   @@@@@@   @@@@@@
//  @@!  @@@ @@!  @@@ @@[email protected][email protected]@@ @@!  @@@ @@!  @@@ [email protected]@
//  @[email protected]@[email protected]!  @[email protected][email protected][email protected]! @[email protected]@[email protected]! @[email protected]  [email protected]! @[email protected][email protected][email protected]!  [email protected]@!!
//  !!:      !!:  !!! !!:  !!! !!:  !!! !!:  !!!     !:!
//   :        :   : : ::    :  :: :  :   :   : : ::.: :
//
// Trash pandas are intelligent creatures who live in hedges and go hunting in
// trash cans at night. Their favorite snack is fish bones, but they'll be happy
// with a nice hat to wear. They are social creatures, although there are only
// 8,888 known trash pandas in the world.
//
// Twitter: https://twitter.com/millywatt_
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';

contract TrashPandas is
    ERC721,
    ERC721Enumerable,
    ERC721Burnable,
    Ownable,
    ReentrancyGuard
{
    string private _baseTokenURI;
    string public provenance;
    uint256 public trashcanOpensBlock =
        0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
    bool public metadataFrozen = false;
    mapping(address => bool) public creators;

    modifier onlyOwnerOrCreators() {
        require(
            owner() == _msgSender() || creators[_msgSender()],
            'Ownable: caller is not the owner or creator'
        );
        _;
    }

    constructor(string memory initialBaseURI)
        ERC721('TrashPandas', 'TrashPandas')
    {
        setBaseURI(initialBaseURI);
    }

    function claim(uint256 tokenId) public nonReentrant {
        require(claimingStarted(), 'Not time yet');
        require(tokenId > 0 && tokenId < 8489, 'Token ID invalid');
        _safeMint(_msgSender(), tokenId);
    }

    function ownerMultiClaim(address recipient, uint256[] memory tokenIds)
        public
        nonReentrant
        onlyOwnerOrCreators
    {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(
                tokenIds[i] > 8488 && tokenIds[i] < 8889,
                'Token ID invalid'
            );
            _safeMint(recipient, tokenIds[i]);
        }
    }

    function claimingStarted() public view returns (bool) {
        return block.number >= trashcanOpensBlock;
    }

    function setClaimingStartBlock(uint256 _newClaimingStartBlock)
        public
        onlyOwner
    {
        trashcanOpensBlock = _newClaimingStartBlock;
    }

    function setProvenance(string memory _newProvenance) public onlyOwner {
        require(!metadataFrozen, 'Metadata frozen');
        provenance = _newProvenance;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        require(!metadataFrozen, 'Metadata frozen');
        _baseTokenURI = _newBaseURI;
    }

    function baseURI() public view returns (string memory) {
        return _baseTokenURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    function setCreator(address creatorAddress, bool isCreator)
        public
        onlyOwner
    {
        creators[creatorAddress] = isCreator;
    }

    function withdraw() public onlyOwner {
        payable(_msgSender()).transfer(address(this).balance);
    }

    function freezeMetadata() public onlyOwner {
        metadataFrozen = true;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}