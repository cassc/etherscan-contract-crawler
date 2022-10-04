// SPDX-License-Identifier: MIT
pragma solidity >=0.4.21 <9.0.0;

// Relevant Libraries
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract ZIPSharks is ERC721, Ownable {
    // Utils Used
    using Counters for Counters.Counter;
    using SafeMath for uint256;
    using Strings for uint256;

    //Team
    address payable kTuck = payable(0xe40c8deA5EdAB02C3B778605cf7b9dD1301062d0);
    address payable samurai =
        payable(0xac4Bc126Ea4D2a1e2bE965f0811c3c51E1817F91);
    address payable mufasa =
        payable(0xf21df340812629D44264474d478be0215Ea60eb6);

    // Properties
    bool public publicSale;
    uint256 public whitelistPrice = 0.02 ether;
    uint256 public mintPrice = 0.03 ether;
    uint16 public maxSupply = 2222;
    string public uri;
    string public pUri;

    bytes32 public root;
    bool public revealed;

    Counters.Counter private _tokenIdTracker;

    // Mappings
    mapping(address => bool) whitelistClaimed;
    mapping(address => uint256) sharksMinted;

    constructor() ERC721("ZIPSharks", "ZIPS") {}

    // Modifiers
    modifier whitelistConfig() {
        require(whitelistClaimed[msg.sender] != true);
        _;
    }

    function whitelistMint(bytes32[] calldata _proof)
        public
        payable
        whitelistConfig
    {
        require(
            (
                MerkleProof.verify(
                    _proof,
                    root,
                    keccak256(abi.encodePacked(msg.sender))
                )
            ),
            "This wallet is not registered. Try again with another wallet."
        );

        uint256 _amount = 0;
        uint256 _balance = msg.value;

        // Uses the balance sent to generate set number of NFTs
        while (_balance >= whitelistPrice) {
            _balance = _balance.sub(whitelistPrice);
            _amount = _amount.add(1);
        }

        // Limits the number minted per wallet
        require(
            sharksMinted[msg.sender].add(_amount) <= 20,
            "Max mint per wallet is 20. Try another wallet."
        );

        // Limits the TokenID to MaxSupply
        require(
            (_tokenIdTracker.current().add(_amount)) <= maxSupply,
            "Current Mint Limit Reached. Try minting less."
        );

        // Runs a for loop to continue minting for the set amount asked.
        for (uint8 counter = 0; counter < _amount; counter++) {
            // 1.Mints the NFT to the current tokenID
            // 2. Maps the current tokenChoice to the current URI
            // 3. Adds one to tokenIDtracker
            _tokenIdTracker.increment();
            _mint(msg.sender, _tokenIdTracker.current());
        }

        // WhitelistClaim and MintNumber Recorded
        sharksMinted[msg.sender] = sharksMinted[msg.sender] + _amount;
        whitelistClaimed[msg.sender] = true;
    }

    function publicMint() public payable {
        require(
            msg.value.mod(mintPrice) == 0,
            "Please mint through the website."
        );

        uint256 _amount = 0;
        uint256 _balance = msg.value;

        // Uses the balance sent to generate set number of NFTs
        while (_balance >= mintPrice) {
            _balance = _balance.sub(mintPrice);
            _amount = _amount.add(1);
        }

        // Limits the number minted per wallet
        require(
            sharksMinted[msg.sender].add(_amount) <= 20,
            "Max mint per wallet is 20. Try another wallet."
        );

        // Limits the TokenID
        require(
            (_tokenIdTracker.current().add(_amount)) <= maxSupply,
            "Current Mint Limit Reached. Try minting less."
        );

        // Runs a for loop to continue minting for the set amount asked.
        for (uint8 counter = 0; counter < _amount; counter++) {
            // 1.Mints the NFT to the current tokenID
            // 2. Maps the current tokenChoice to the current URI
            // 3. Adds one to tokenIDtracker
            _tokenIdTracker.increment();
            _mint(msg.sender, _tokenIdTracker.current());
        }

        sharksMinted[msg.sender] = sharksMinted[msg.sender] + _amount;
    }

    // ADMIN Methods

    // SharkDrop Method
    function sharkDrop(address[] calldata _addresses, uint8 _x)
        public
        onlyOwner
    {
        for (uint256 counter = 0; counter < _addresses.length; counter++) {
            // Mints x amount per wallet inputed
            for (uint256 n = 0; n < _x; n++) {
                _tokenIdTracker.increment();
                _mint(_addresses[counter], _tokenIdTracker.current());
                sharksMinted[_addresses[counter]].add(1);
            }
        }
    }

    // Reveals Sharks
    function sharkReveal() public onlyOwner {
        bool current = revealed;
        revealed = !current;
    }

    // Switches sale to public
    function switchToPublic() public onlyOwner {
        bool current = publicSale;
        publicSale = !current;
    }

    //Withdraw Method
    function withdraw() public onlyOwner {
        uint256 _balance = address(this).balance;
        uint256 _balanceDiv = _balance.div(100);
        kTuck.transfer(_balanceDiv.mul(4));
        mufasa.transfer(_balanceDiv.mul(11));
        samurai.transfer(_balanceDiv.mul(85));
    }

    // TotalSupply Method
    function totalSupply() public view returns (uint256) {
        return _tokenIdTracker.current();
    }

    // Update Merkle Root
    function updateRoot(bytes32 _x) public onlyOwner {
        root = _x;
    }

    // URI methods

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        if (revealed) {
            return
                string(
                    abi.encodePacked(uri, Strings.toString(tokenId), ".json")
                );
        } else {
            return
                string(
                    abi.encodePacked(pUri, Strings.toString(tokenId), ".json")
                );
        }
    }

    function setBaseUri(string memory _uri) public onlyOwner {
        uri = _uri;
    }

    function setPreReveal(string memory _uri) public onlyOwner {
        pUri = _uri;
    }

    // OVERRIDE BaseURI Methods
    function _baseURI() internal view virtual override returns (string memory) {
        return uri;
    }
}