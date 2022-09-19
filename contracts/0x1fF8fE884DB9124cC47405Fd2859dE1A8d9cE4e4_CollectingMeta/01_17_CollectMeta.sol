// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "./ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract CollectingMeta is ERC721A, Ownable, ReentrancyGuard {
    using Strings for uint256;

    string public baseURI;
    string public baseExtension = "";
    uint256 public costOne = 0.07 ether;
    uint256 public costTwo = 0.08 ether;
    uint256 public costThree = 0.1 ether;
    uint256 public currentCost;
    uint256 public tokenTierOne = 1000;
    uint256 public tokenTierTwo = 2000;
    uint256 public maxSupply = 18000;
    uint256 public maxPerTx = 20;
    bool public paused = false;
    bool public isClaimLive = false;
    uint256 public claimedAmount;

    bytes32 public airDropMerkleRoot;
    mapping(address => uint256) public airDropSaleClaimed;
    mapping(address => bool) public airDropSaleClaimedChecker;

    address _community = 0xF78F59412c9F9cB57227a925018565A3f0CBBc9d;
    address _teamOne = 0x21077b095626b71A2722071453F9E994468Db81C;
    address _teamTwo = 0x9e4A358854fE92d9bf17af6672503c38C52561D5;

    constructor() ERC721A("Collecting Meta", "CMETA") {
        setBaseURI("http://api.collectingmeta.com/api/");
    }

    function claim(bytes32[] calldata _merkleProof, uint256 tokens) public {
        uint256 supply = totalSupply();
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(isClaimLive, "claim is not live");
        require(
            MerkleProof.verify(_merkleProof, airDropMerkleRoot, leaf),
            "invalid merkle proof"
        );
        require(supply + tokens <= maxSupply, "max claim supply reached");
        if (!airDropSaleClaimedChecker[msg.sender]) {
            airDropSaleClaimedChecker[msg.sender] = true;
            airDropSaleClaimed[msg.sender] = tokens;
        }
        require(
            airDropSaleClaimed[msg.sender] > 0,
            "address has already minted allowed tokens"
        );
        airDropSaleClaimed[msg.sender] =
            airDropSaleClaimed[msg.sender] -
            tokens;
        _safeMint(msg.sender, tokens);
        claimedAmount = claimedAmount + tokens;
    }

    function airDropToList(
        address[] calldata _addresses,
        uint256[] memory _amount
    ) public onlyOwner {
        uint256 supply = totalSupply();
        uint256 _mintAmount = 0;
        for (uint256 i = 0; i < _amount.length; i++) {
            _mintAmount += _amount[i];
        }
        require(
            _addresses.length == _amount.length,
            "addresses and amounts are not equal length"
        );
        require(_mintAmount > 0, "need to mint at least 1 token");
        require(supply + _mintAmount <= maxSupply, "max token limit exceeded");

        for (uint256 i = 0; i < _amount.length; i++) {
            _safeMint(_addresses[i], _amount[i]);
        }
    }

    function passHolderMint(uint256 tokens) external payable nonReentrant {
        uint256 supply = totalSupply();
        require(!paused, "contract is paused");
        require(tokens > 0, "need to mint at least 1 token");
        require(supply + tokens <= maxSupply, "collection is sold out");
        require(getPassBalance(msg.sender) > 0, "no pass held");
        require(tokens <= maxPerTx, "max mint amount per tx exceeded");
        require(msg.value >= getCurrentCost() * tokens, "insufficient funds");
        _safeMint(_msgSender(), tokens);
    }

    function mint(uint256 tokens) external payable nonReentrant {
        require(!paused, "contract is paused");
        uint256 supply = totalSupply();
        require(tokens > 0, "need to mint at least 1 token");
        require(supply + tokens <= maxSupply, "collection is sold out");
        require(tokens <= maxPerTx, "max mint amount per tx exceeded");
        require(msg.value >= getCurrentCost() * tokens, "insufficient funds");
        _safeMint(_msgSender(), tokens);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721AMetadata: URI query for nonexistent token"
        );

        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        tokenId.toString(),
                        baseExtension
                    )
                )
                : "";
    }

    function getCurrentCost() public view returns (uint256 _currentCost) {
        _currentCost = currentCost;
        uint256 supply = totalSupply() + 1;
        if (supply <= tokenTierOne) {
            _currentCost = costOne;
        } else if (supply > tokenTierOne && supply <= tokenTierTwo) {
            _currentCost = costTwo;
        } else if (supply > tokenTierTwo) {
            _currentCost = costThree;
        }
        return _currentCost;
    }

    function getPassBalance(address _user)
        public
        view
        returns (uint256 _passBalance)
    {
        uint256 passBalance = IERC721Enumerable(
            0x19350eb381aB2f88d274e740bD062Ab5FF15542E
        ).balanceOf(_user);
        return passBalance;
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    //only owner
    function setAirDropMerkleRoot(bytes32 merkle_root) external onlyOwner {
        airDropMerkleRoot = merkle_root;
    }

    function setCostOne(uint256 _newCost) public onlyOwner {
        costOne = _newCost;
    }

    function setCostTwo(uint256 _newCost) public onlyOwner {
        costTwo = _newCost;
    }

    function setCostThree(uint256 _newCost) public onlyOwner {
        costThree = _newCost;
    }

    function setTokenTierOne(uint256 _newTokenTier) public onlyOwner {
        tokenTierOne = _newTokenTier;
    }

    function setTokenTierTwo(uint256 _newTokenTier) public onlyOwner {
        tokenTierTwo = _newTokenTier;
    }

    function setMaxSupply(uint256 _newMaxSupply) public onlyOwner {
        maxSupply = _newMaxSupply;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setBaseExtension(string memory _newBaseExtension)
        public
        onlyOwner
    {
        baseExtension = _newBaseExtension;
    }

    function pause(bool _state) public onlyOwner {
        paused = _state;
    }

    function setIsClaimLive(bool _state) public onlyOwner {
        isClaimLive = _state;
    }

    function setWithdrawWallets(
        address community,
        address teamOne,
        address teamTwo
    ) public onlyOwner {
        _community = community;
        _teamOne = teamOne;
        _teamTwo = teamTwo;
    }

    function withdrawMoney() external nonReentrant {
        uint256 balance = address(this).balance;
        payable(_community).transfer((balance * 80) / 100);
        payable(_teamOne).transfer((balance * 10) / 100);
        payable(_teamTwo).transfer((balance * 10) / 100);
    }

    function withdrawFallback() public payable onlyOwner nonReentrant {
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(success);
    }
}