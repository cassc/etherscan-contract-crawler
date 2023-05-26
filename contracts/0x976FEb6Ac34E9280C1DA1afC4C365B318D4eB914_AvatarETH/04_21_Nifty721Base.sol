pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol';

import '@openzeppelin/contracts/utils/Strings.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '../royalties/ERC2981.sol';
import './MintAdmin.sol';

contract Nifty721Base is ERC721URIStorage, ERC2981, MintAdmin {
    using Strings for uint256;
    string _uri;
    //mapping(uint256 => string) public cuids;
    //bytes4 private constant _INTERFACE_ID_ERC2981 = 0xc155531d;

    event RoyaltyWalletChanged(address indexed previousWallet, address indexed newWallet);

    event RoyaltyFeeChanged(uint24 previousFee, uint24 newFee);
    event URIChanged(string newURI);

    uint256 public constant ROYALTY_FEE_DENOMINATOR = 100000;
    address public royaltyWallet;
    uint24 public royaltyFee = 6000;
    string public contractURI;

    // TODO: set royalty information in constructor
    constructor(
        string memory uri,
        string memory name,
        string memory symbol,
        address owner
    ) public ERC721(name, symbol) MintAdmin(owner) {
        _uri = uri;
        contractURI = uri;
    }

    function setContractURI(string memory _contractURI) public isAdmin {
        contractURI = _contractURI;
    }

    function setRoyaltyWallet(address _royaltyWallet) external isAdmin {
        _setRoyaltyWallet(_royaltyWallet);
    }

    function setRoyaltyFee(uint24 _royaltyFee) external isAdmin {
        _setRoyaltyFee(_royaltyFee);
    }

    function setbaseURI(string memory newuri) external isAdmin {
        _uri = newuri;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _uri;
    }

    function royaltyInfo(uint256, uint256 value)
        external
        view
        override(ERC2981)
        returns (address receiver, uint256 royaltyAmount)
    {
        return (royaltyWallet, (value * royaltyFee) / ROYALTY_FEE_DENOMINATOR);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC2981, ERC721, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _setRoyaltyWallet(address _royaltyWallet) internal {
        require(_royaltyWallet != address(0), 'INVALID_WALLET');
        emit RoyaltyWalletChanged(royaltyWallet, _royaltyWallet);
        royaltyWallet = _royaltyWallet;
    }

    function _setRoyaltyFee(uint24 _royaltyFee) internal {
        require(_royaltyFee <= ROYALTY_FEE_DENOMINATOR, 'INVALID_FEE');
        emit RoyaltyFeeChanged(royaltyFee, _royaltyFee);
        royaltyFee = _royaltyFee;
    }

    function burn(uint256 tokenId) public {
        //solhint-disable-next-line max-line-length
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            'ERC721: caller is not owner nor approved'
        );
        _burn(tokenId);
    }
}