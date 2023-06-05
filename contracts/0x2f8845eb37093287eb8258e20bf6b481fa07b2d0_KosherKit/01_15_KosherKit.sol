// SPDX-License-Identifier: MIT
// Authors: 0xGOOF, 0xJomahe

pragma solidity >=0.8.0 <0.9.0;

import './ERC721Enumerable.sol';
import './Ownable.sol';
import './MerkleProof.sol';
import './ReentrancyGuard.sol';

contract KosherKit is ERC721Enumerable, Ownable, ReentrancyGuard {
    using Strings for uint256;

    uint256 public immutable maxSupply = 450;
    uint256 public price = .199 ether;
    uint256 public renewalPrice = .199 ether;

    bool public initMint = true;

    string public baseURI;

    bool public paused = true;
    bool public whiteListMintEnabled;
    bool public publicSaleEnabled;

    uint256 tokenIdCounter;
    uint256[] public burnedIds;

    mapping(uint256 => uint256) public idToExpirys;
    mapping(address => bool) public mintClaimed;
    address[] public minters;

    bytes32 public merkleRoot;

    constructor() ERC721("Kosher Kit", "KK") {
        tokenIdCounter = 0;
    }

    modifier validAmount() {
        require(1 + totalSupply() <= maxSupply,"Max supply!");
        _;
    }

    modifier validValue() {
        require(msg.value >= price, "Insufficient funds");
        _;
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "No contracts");
        _;
    }

    function whiteListMint(bytes32[] calldata _merkleProof) external payable nonReentrant callerIsUser validAmount validValue {
        require(!paused && whiteListMintEnabled, "WL mint hasn't begun");
        require(!mintClaimed[msg.sender], "Already minted");

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(
            MerkleProof.verify(_merkleProof, merkleRoot, leaf),
            "Invalid Merkle Proof!"
        );

        uint256 tokenID = setTokenID();

        mintClaimed[msg.sender] = true;
        minters.push(msg.sender);
        idToExpirys[tokenID] = block.timestamp + 30 days;
        _safeMint(msg.sender, tokenID);
    }

    function setTokenID() internal returns (uint) {
        // If initial minting is done, but at least 1 token has been burnt
        uint tokenID;
        if (tokenIdCounter >= maxSupply) {
            require(burnedIds.length > 0, "No Burnt IDs");
            tokenID = burnedIds[burnedIds.length - 1];
            burnedIds.pop();
        } else {
            ++tokenIdCounter;
            tokenID = tokenIdCounter;
        }
        return tokenID;
    }

    function mint() external payable nonReentrant callerIsUser validAmount validValue {
        require(!paused && publicSaleEnabled, "Sale not enabled");
        require(!mintClaimed[msg.sender], "Already minted");

        uint256 tokenID = setTokenID();

        mintClaimed[msg.sender] = true;
        minters.push(msg.sender);
        idToExpirys[tokenID] = block.timestamp + 30 days;
        _safeMint(msg.sender, tokenID);
    }

    function mintForAddress(
        address _to
    ) external validAmount onlyOwner {
        uint256 tokenID = setTokenID();

        idToExpirys[tokenID] = block.timestamp + 30 days;
        _safeMint(_to, tokenID);
    }

    function burn(uint _tokenId) external onlyOwner {
        burnedIds.push(_tokenId);
        _burn(_tokenId);
    }

    function renewToken(uint _tokenId) external payable {
        require(_exists(_tokenId), "Token not minted!");
        require(msg.value >= renewalPrice, "Insufficient funds!");

        idToExpirys[_tokenId] = block.timestamp > idToExpirys[_tokenId] ?
                                block.timestamp + 30 days :
                                idToExpirys[_tokenId] + 30 days;
    }

    function ownerRenewToken(uint _tokenId) external onlyOwner {
        require(_exists(_tokenId), "Token not minted!");

        idToExpirys[_tokenId] = block.timestamp > idToExpirys[_tokenId] ?
                                block.timestamp + 30 days :
                                idToExpirys[_tokenId] + 30 days;
    }

    function toggleWhitelistSale() external onlyOwner {
        whiteListMintEnabled = !whiteListMintEnabled;
    }

    function togglePublicSaleStarted() external onlyOwner {
        publicSaleEnabled = !publicSaleEnabled;
    }

    function togglePause() external onlyOwner {
        paused = !paused;
    }

    function setWhitelistMerkleRoot(bytes32 whitelistRoot) external onlyOwner {
        merkleRoot = whitelistRoot;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function toggleInitialMint() external onlyOwner {
        initMint = !initMint;
    }

    function changeMintPrice(uint _newPriceInWEI) external onlyOwner {
        price = _newPriceInWEI;
    }

    function changeRenewalPrice(uint _newPriceInWEI) external onlyOwner {
        renewalPrice = _newPriceInWEI;
    }

    function populateBurnedIDs() external onlyOwner {
        delete burnedIds;
        for (uint i = 1; i <= maxSupply; i++) {
            if (!_exists(i)) {
                burnedIds.push(i);
            }
        }
    }

    function pushToBurnedIDs(uint _tokenID) external onlyOwner {
        burnedIds.push(_tokenID);
    }

    function resetMinters() external onlyOwner {
        for (uint i; i < minters.length; ++i) {
            mintClaimed[minters[i]] = false;
        }
        delete minters;
    }

    function withdrawAll() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "Insufficent balance");

        uint256 addedPCT = 1;
        if (initMint) {
            addedPCT = 0;
            _withdraw(0x17Be91E788ccFe82E22aA6e9076A2a4f4c13F9D0, ((balance * 4) / 100)); //4% to dev
        }

        _withdraw(0x1243cFF98A1066381D760578a9b4432B31e3c693, ((balance * (29 + addedPCT)) / 100)); //29% to M
        _withdraw(0xfcB86dd15ef02E31F18e6BDaf0b36f0e572CddEE, ((balance * (19 + addedPCT)) / 100)); //19% to C
        _withdraw(0x8aC9A5AcE0B0AcA69834eC04B8FA44450126462f, ((balance * (19 + addedPCT)) / 100)); //19% to G
        _withdraw(0x7C2956ECa6BF48A2956a03787284BcAB6054E221, address(this).balance); //29% to K (coded like this so there is no remainder left in contract)
    }

    function _withdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{ value: _amount }("");
        require(success, "Failed to withdraw Ether");
    }
}