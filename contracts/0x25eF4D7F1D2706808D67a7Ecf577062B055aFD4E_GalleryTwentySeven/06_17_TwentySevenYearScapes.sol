// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@1001-digital/erc721-extensions/contracts/WithLimitedSupply.sol";

import "./WithMetadata.sol";

/*

   @@@@@@   @@@@@@@@  @@@ @@@   @@@@@@
  @@@@@@@@  @@@@@@@@  @@@ @@@  @@@@@@@
       @@@       @@!  @@! [email protected]@  [email protected]@
      @[email protected]       [email protected]!   [email protected]! @!!  [email protected]!
     [email protected]       @!!     [email protected][email protected]!   [email protected]@!!
    !!:       !!!       @!!!    [email protected]!!!
   !:!       !!:        !!:         !:!
  :!:       :!:         :!:        !:!
  :: :::::   ::          ::    :::: ::
  :: : :::  : :          :     :: : :

*/
contract TwentySevenYearScapes is
    ERC721,
    WithMetadata,
    WithLimitedSupply
{
    // The Gallery 27 Auction House contract address
    address private _auctionContract;

    /// @dev Emitted when a new token is minted
    event Mint(uint256 indexed tokenId, string cid);

    /// Initialize the TwentySevenYearScapes Contract
    /// @dev initialize the contract
    constructor()
        ERC721("TwentySevenYearScapes", "27YS")
        WithMetadata("ipns://k51qzi5uqu5dihww7e3ugve5qc5ziwemg3ecbllglobgqge6ibqjfjtzobfp7v")
        WithLimitedSupply(10000)
    {}

    /// Mint a new Twenty Seven Year Scape
    /// @param _to The address of the recipient of the token
    /// @param _tokenId The id of the token to mint
    /// @param _cid The content hash of the token to mint
    function mint(address _to, uint256 _tokenId, string memory _cid) public ensureAvailability {
        require(_msgSender() == auctionContract(), "Not allowed to mint");

        nextToken();

        _safeMint(_to, _tokenId);

        emit Mint(_tokenId, _cid);
    }

    /// @dev Returns the address of the auction contract.
    function auctionContract() public view virtual returns (address) {
        return _auctionContract;
    }

    /// @dev Updates the auction contract address
    function setAuctionContract(address contractAddress) external onlyOwner {
        _auctionContract = contractAddress;
    }

    /// @dev Get the tokenURI for a specific token
    function tokenURI(uint256 tokenId)
        public view override(WithMetadata, ERC721)
        returns (string memory)
    {
        return WithMetadata.tokenURI(tokenId);
    }

    /// @dev Configure the baseURI for the tokenURI method
    function _baseURI()
        internal view override(WithMetadata, ERC721)
        returns (string memory)
    {
        return WithMetadata._baseURI();
    }
}