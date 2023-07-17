// SPDX-License-Identifier: MIT
// Developed by MufasaBrownie.eth

pragma solidity >=0.4.22 <0.9.0;

// Relevant Libraries
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract PridePass is ERC721, Ownable {
    // Utils Used
    using Strings for uint256;
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    // Properties
    uint256 public totalSupply = 1000;
    bool public publicSale;
    string uri;
    bytes32 public immutable root =
        0xc742f076fd5c5e3f25bcbfbdefb6434ddb4a0ca57a05c6b3619b4b613ad11dfe;

    // Mappings
    mapping(address => bool) tokenClaimed;
    mapping(address => bool) pridelist;

    //Counter
    Counters.Counter private _tokenIdTracker;

    constructor() ERC721("PridePass", "PRIDE") {}

    //Modifiers
    modifier mintConfig(bytes32[] calldata _proof) {
        if (publicSale != true) {
            bool _merkle = MerkleProof.verify(
                _proof,
                root,
                keccak256(abi.encodePacked(msg.sender))
            );

            require(
                _merkle == true || pridelist[msg.sender] == true,
                "Sorry the connected wallet is not eligible for a private pride pass."
            );
        }

        require(tokenClaimed[msg.sender] != true, "Pass already claimed.");
        require(
            _tokenIdTracker.current().add(1) <= totalSupply,
            "Total Supply Exceeded. Stay tuned for more Do Good Alpha projects!"
        );
        _;
    }

    // Mint Method
    function pridePass(bytes32[] calldata _proof) public mintConfig(_proof) {
        _tokenIdTracker.increment();
        _mint(msg.sender, _tokenIdTracker.current());
        tokenClaimed[msg.sender] = true;
    }

    // Admin Methods

    function adminPass(uint256 _amount, address _to) public onlyOwner {
        for (uint8 counter = 0; counter < _amount; counter++) {
            // Mints the NFT to the current tokenID and adds one
            _tokenIdTracker.increment();
            super._mint(_to, _tokenIdTracker.current());
        }
    }

    function addToPrideList(address _x) public onlyOwner {
        pridelist[_x] = true;
    }

    function switchToPublic() public onlyOwner {
        bool current = publicSale;
        publicSale = !current;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        return
            string(abi.encodePacked(uri, Strings.toString(tokenId), ".json"));
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return uri;
    }

    function setBaseUri(string memory _uri) public onlyOwner {
        uri = _uri;
    }

    // Donations

    function donate() public payable {}

    // Wallets

    address payable geekchief =
        payable(0x91f328DF6D5866D544fBbe98F3F0b007a234951A);
    address payable shermo =
        payable(0x0c24f3EF0dD2d7C084432339AA673dDD5Ccf64F6);
    address payable samurai =
        payable(0xac4Bc126Ea4D2a1e2bE965f0811c3c51E1817F91);
    address payable prism = payable(0xfDC66caea47B17933561619a2DD326632Eda7884);
    address payable outrightInt =
        payable(0x9D5025B327E6B863E5050141C987d988c07fd8B2);
    address payable jewls = payable(0x9a335eBC75ce2529ECa60Fac10080758eE2ee9B0);
    address payable karan = payable(0xF088e27278A8542F35e5d0A2C986a65B234224b7);
    address payable danny = payable(0x09C36F0D824f030aCd52E1dC15a583b70508bbf0);
    address payable cryptophoenix =
        payable(0xb261F055621fb3D19b86CD87d499b5aD9a561115);
    address payable nftBoho =
        payable(0xfcFC32333E8E4A97F887489B488a242dFE2AdC5E);
    address payable codyfied =
        payable(0x74e95632Cfe531bc6f3376dD7749A1c582d8c1eD);
    address payable doGood =
        payable(0xEac96AB87066822542b2F8b5837F4965E0Ef4032);
    address payable mufasa =
        payable(0xf21df340812629D44264474d478be0215Ea60eb6);
    address payable benP = payable(0x10c5D48B6b4B64d2f6c5e58dFf55AaFaBdE17709);

    function divyDonations() public onlyOwner {
        uint256 _balance = address(this).balance;
        require(_balance > 0 ether);
        uint256 _balancePoint = _balance.div(100);
        geekchief.transfer(_balancePoint);
        jewls.transfer(_balancePoint.mul(4));
        nftBoho.transfer(_balancePoint.mul(4));
        codyfied.transfer(_balancePoint.mul(4));
        benP.transfer(_balancePoint.mul(5));
        cryptophoenix.transfer(_balancePoint.mul(5));
        danny.transfer(_balancePoint.mul(6));
        shermo.transfer(_balancePoint.mul(7));
        samurai.transfer(_balancePoint.mul(7));
        karan.transfer(_balancePoint.mul(7));
        mufasa.transfer(_balancePoint.mul(7));
        doGood.transfer(_balancePoint.mul(13));
        prism.transfer(_balancePoint.mul(15));
        outrightInt.transfer(_balancePoint.mul(15));
    }
}