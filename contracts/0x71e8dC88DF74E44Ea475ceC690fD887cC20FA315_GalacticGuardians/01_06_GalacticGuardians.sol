// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@rari-capital/solmate/src/utils/ReentrancyGuard.sol";
import "@rari-capital/solmate/src/tokens/ERC721.sol";

contract GalacticGuardians is ReentrancyGuard, Ownable, ERC721 {
    uint256 public totalSupply;

    uint256 public constant MINT_PRICE = 0.008 ether;
    uint256 public constant MAX_SUPPLY = 8888;

    uint256 public constant MAX_PER_WALLET = 10;
    uint256 public constant MAX_FREE_PER_WALLET = 2;

    uint256 public constant MAX_PER_TX = 2;
    uint256 public constant MAX_FREE_PER_TX = 2;

    mapping(address => uint256) addressToPayableMintCount;
    mapping(address => uint256) addressToFreeMintCount;

    string internal _baseURI;

    constructor(string memory _uri)
        ERC721("GalacticGuardians", "GALACTICGUARDIANS")
    {
        _baseURI = _uri;

        address[] memory team = new address[](5);
        // Commander Gayamede
        team[0] = 0xC0Ac177CCFD53001182169568747fCCAAFD5c98B;
        // Commander Vesta
        team[1] = 0x21F8016F77040afF5402a34fB80b691305535803;
        // Commander Orion
        team[2] = 0x06039a2C535558E5B256CEAcD728E264F9f295bd;
        // Commander Ariel
        team[3] = 0xC0Ac177CCFD53001182169568747fCCAAFD5c98B;
        // dev
        team[4] = 0xDead879244402f85AE13EE1d1f1B8dE540D57843;
        address[] memory gayamede = new address[](1);
        gayamede[0] = 0xC0Ac177CCFD53001182169568747fCCAAFD5c98B;
        // airdrop for the team
        airdrop(team, 5);

        airdrop(gayamede, 25);

        transferOwnership(gayamede[0]);
    }

    function _mint() internal {
        _safeMint(msg.sender, totalSupply);
        totalSupply++;
    }

    function freeMint(uint256 _amount) external nonReentrant {
        require(totalSupply + _amount <= 1050, "FREE_MINT_OUT");
        require(
            _amount > 0 && _amount <= MAX_FREE_PER_TX,
            "EXCEEDS_MAX_FREE_PER_TX"
        );
        // require(
        //     addressToFreeMintCount[msg.sender] + _amount <= MAX_FREE_PER_WALLET,
        //     "EXCEEDS_MAX_FREE_PER_WALLET"
        // );
        for (uint256 i; i < _amount; i++) {
            _mint();
            addressToFreeMintCount[msg.sender]++;
        }
    }

    function mint(uint256 _amount) external payable nonReentrant {
        // require(totalSupply + _amount >= 1000, "FREE_MINT_IS_STILL_ACTIVE");

        require(totalSupply + _amount < MAX_SUPPLY, "EXCEEDS_SUPPLY");

        require(msg.value >= MINT_PRICE * _amount, "NOT_ENOUGH_ETHER");

        require(_amount > 0 && _amount <= MAX_PER_TX, "EXCEEDS_MAX_PER_TX");

        require(
            addressToPayableMintCount[msg.sender] + _amount <= MAX_PER_WALLET,
            "EXCEEDS_MAX_PER_WALLET"
        );

        for (uint256 i; i < _amount; i++) {
            _mint();
            addressToPayableMintCount[msg.sender]++;
        }
    }

    function airdrop(address[] memory _addresses, uint256 _count)
        public
        onlyOwner
    {
        for (uint256 i = 0; i < _addresses.length; i++) {
            for (uint256 x = 0; x < _count; x++) {
                _safeMint(_addresses[i], totalSupply);
                totalSupply++;
            }
        }
    }

    function setBaseURI(string memory _uri) public onlyOwner {
        _baseURI = _uri;
    }

    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721)
        returns (string memory)
    {
        require(_ownerOf[tokenId] != address(0), "NOT_EXISTS");
        return string(abi.encodePacked(_baseURI, Strings.toString(tokenId)));
    }
}