pragma solidity >=0.8.0;
//SPDX-License-Identifier: MIT

//import "hardhat/console.sol";
import '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import '@openzeppelin/contracts/utils/Counters.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/Strings.sol';

contract ArtMinter is ERC721, Ownable {
    using Strings for uint256;
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIds;

    // Base URI
    string private _baseURIVal;

    // tokenURI Storage for if only minting editions (i.e. duplicates of the )
    string public editionTokenURI;

    // Total Number of mints
    uint256 public totalMints;

    // Total Number of mints
    uint256 public mintPrice;

    // Payee
    address payable public payee;

    event Sold(uint256 indexed tokenId, uint256 indexed amount, address buyer);

    constructor(
        string memory _contractName,
        string memory _symbol,
        string memory _baseURIArg,
        string memory _editionTokenURI,
        uint256 _totalMints,
        uint256 _price,
        address payable _payee
    ) ERC721(_contractName, _symbol) {
        _baseURIVal = _baseURIArg;
        editionTokenURI = _editionTokenURI;
        totalMints = _totalMints;
        mintPrice = _price;
        payee = _payee;
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseURIVal;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(totalMints >= tokenId, 'Token does not exist');
        string memory baseURI = _baseURI();
        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, tokenId.toString()))
                : editionTokenURI;
    }

    function nextTokenId() public view returns (uint256) {
        return _tokenIds.current() + 1;
    }

    function mintItem() public payable returns (uint256) {
        // Only mint if below limit
        require(totalMints >= _tokenIds.current(), 'Maxed out on Mints!!');

        // Must pay mint price
        require(msg.value >= mintPrice, 'Not enough money for mints bro!');

        _tokenIds.increment();

        uint256 id = _tokenIds.current();
        _mint(msg.sender, id);
        (bool successPayee, ) = payee.call{value: mintPrice}('');
        require(successPayee, 'send not successful payee');
        (bool successRefund, ) = payee.call{value: (msg.value - mintPrice)}('');
        require(successRefund, 'send not successful refund');
        emit Sold(id, mintPrice, msg.sender);
        return id;
    }
}