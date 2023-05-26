// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

// import "./ERC721A/contracts/extensions/ERC721ABurnable.sol";
import "./ERC721A/contracts/mocks/ERC721ABurnableMock.sol";
import "./ERC721A/contracts/mocks/StartTokenIdHelper.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
}

contract ApocalypticApesJuice is StartTokenIdHelper, ERC721A, ERC721ABurnable {
    event ClaimJuice(address indexed summoner, uint256 times);

    bool claimStart;
    string public baseURI;

    string name_ = "Apocalyptic Apes Juice";
    string symbol_ = "AAJUICE";
    string baseURI_ = "ipfs://";

    uint256 startTokenId_ = 1;
    uint256 public totalCount = 8888;

    address payable public owner;
    IERC721Enumerable public apocalyptic = IERC721Enumerable(address(0));

    mapping(uint256 => bool) public claimed;

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner");
        _;
    }

    constructor()
        StartTokenIdHelper(startTokenId_)
        ERC721A(name_, symbol_)
    {
        owner = payable(msg.sender);
    }
    function exists(uint256 tokenId) public view returns (bool) {
        return _exists(tokenId);
    }

    function safeMintBatch(address to, uint256[] calldata apes) public onlyOwner {
        require(apes.length + totalSupply() <= totalCount, "All juice claimed!");
        uint256 toMint;

        for (uint256 i = 0; i < apes.length; i++) {
            uint tokenID = apes[i];
            if (!claimed[tokenID]) {
                toMint++;
                claimed[tokenID] = true;
            }
        }
        _safeMint(to, toMint);
    }
    
    function safeMint(address to, uint256 toMint) public onlyOwner {
        require(toMint + totalSupply() <= totalCount, "All juice claimed!");
        _safeMint(to, toMint);
    }

    function getOwnershipAt(uint256 index) public view returns (TokenOwnership memory) {
        return _ownerships[index];
    }

    function totalMinted() public view returns (uint256) {
        return _totalMinted();
    }

    function _startTokenId() internal view override returns (uint256) {
        return startTokenId;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory _newURI) public onlyOwner {
        baseURI = _newURI;
    }

    function setApocalypticApes(address _newAddress) public onlyOwner {
        apocalyptic = IERC721Enumerable(_newAddress);
    }

    function setClaimStart(bool _claimStart) public onlyOwner {
        claimStart = _claimStart;
    }

    function claimJuice() public returns(uint256){
        require(claimStart, "Claiming has not started");
        uint256 apesOwned = apocalyptic.balanceOf(msg.sender);
        uint256 tokenID;

        uint256 toMint;

        for (uint256 i = 0; i < apesOwned; i++) {
            tokenID = apocalyptic.tokenOfOwnerByIndex(msg.sender, i);
            if (!claimed[tokenID]) {
                toMint++;
                claimed[tokenID] = true;
            }
        }

        if(toMint > 0){
            require(toMint + totalSupply() <= totalCount, "All juice claimed!");
            _safeMint(msg.sender, toMint);
        }

        return toMint;
    }

    function withdrawAll() public payable onlyOwner {
        uint256 contract_balance = address(this).balance;
        require(payable(owner).send(contract_balance));
    }

    function rescueTokens(
        address recipient,
        address token,
        uint256 amount
    ) public onlyOwner {
        IERC20(token).transfer(recipient, amount);
    }

    function changeOwner(address payable _newowner) external onlyOwner {
        owner = _newowner;
    }
}