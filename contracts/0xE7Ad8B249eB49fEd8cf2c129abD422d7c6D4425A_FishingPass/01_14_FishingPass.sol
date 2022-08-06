// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract FishingPass is ERC721, Ownable {
    using Strings for uint256;
    using SafeMath for uint8;
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    // Properties
    uint256 public mintPrice;
    uint16 public mintLimit;
    string public _chosenUri;
    bool public publicSale;
    address payable samurai =
        payable(0xac4Bc126Ea4D2a1e2bE965f0811c3c51E1817F91);
    address payable mufasa =
        payable(0xf21df340812629D44264474d478be0215Ea60eb6);

    bytes32 public immutable root =
        0x4d703f301ab00bd1914b5b12ae890912b3bdca39e5523d9aa82e97b9515787c0;

    // Mappings
    mapping(address => bool) tokenClaimed;

    constructor() ERC721("FishingPass", "ZPF") {
        mintPrice = 0.03 ether;
        mintLimit = 100;
        publicSale = false;
    }

    // Counter to ID NFTs
    Counters.Counter private _tokenIdTracker;

    modifier mintConfig(bytes32[] calldata _proof) {
        if (publicSale != true) {
            bool _merkle = MerkleProof.verify(
                _proof,
                root,
                keccak256(abi.encodePacked(msg.sender))
            );

            require(
                _merkle == true,
                "Sorry the connected wallet is not eligible for a license."
            );
        }

        require(tokenClaimed[msg.sender] != true, "License already claimed.");
        _;
    }

    // Public Mint Function
    function mint(bytes32[] calldata _proof) public payable mintConfig(_proof) {
        // Limits the TokenID

        require(
            msg.value >= 0.03 ether,
            "License price: 0.03 ETH. Please send the correct ether amount."
        );

        require(
            (_tokenIdTracker.current().add(1)) <= mintLimit,
            "Current Mint Limit Reached."
        );

        _tokenIdTracker.increment();
        super._mint(msg.sender, _tokenIdTracker.current());
        tokenClaimed[msg.sender] = true;
    }

    /// ADMIN METHODS ///

    // Switch to Public Method
    function switchToPublic() public onlyOwner {
        bool current = publicSale;
        publicSale = !current;
    }

    //Set BaseURI Method
    function setBaseUri(string memory _baseUri) public onlyOwner {
        _chosenUri = _baseUri;
    }

    // Returns the token URI
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(_chosenUri, Strings.toString(tokenId), ".json")
            );
    }

    // Overrides current BaseUri to show NFTs
    function _baseURI() internal view virtual override returns (string memory) {
        return _chosenUri;
    }

    function withdraw() public onlyOwner {
        // Requires that the balance is more than 0ETH
        require(address(this).balance > 0 ether, "Balance is 0");
        uint256 _balance = address(this).balance;
        uint256 _balancePoint = _balance.div(10);
        samurai.transfer(_balancePoint.mul(6));
        mufasa.transfer(_balancePoint.mul(4));
    }
}