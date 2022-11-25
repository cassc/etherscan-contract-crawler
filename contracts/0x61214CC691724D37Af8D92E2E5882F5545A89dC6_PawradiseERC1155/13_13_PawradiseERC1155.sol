// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

// import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
// import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155URIStorage.sol";

contract PawradiseERC1155 is Ownable, ERC1155URIStorage {
    mapping(address => bool) public minters;
    mapping(uint256 => uint256) public supply;
    mapping(address => uint256) public mintSupply;

    uint256 startTime;
    uint256 public constant MAX_SUPPLY = 1000;
    uint256 public constant MAX_MINT_SUPPLY_PER_PERSON = 1;
    uint256 public constant MAX_MINT_SUPPLY_PER_WL_PERSON = 2;
    bool public mintingFinished = false;

    // Contract name
    string public name;
    // Contract symbol
    string public symbol;

    constructor(string memory _name, string memory _symbol)
        ERC1155("https://pawradise.xyz/")
    {
        name = _name;
        symbol = _symbol;
        minters[msg.sender] = true; // The deployer is the first minter
        startTime = 1669334400;
    }

    function claim(uint256 id) public {
        require(mintingFinished == false, "Minting is finished");
        require(supply[id] < MAX_SUPPLY, "Max supply reached");
        if (minters[msg.sender]) {
            require(
                mintSupply[msg.sender] < MAX_MINT_SUPPLY_PER_WL_PERSON,
                "You have reached your max claim (2 NFT)"
            );
            require(getCurrentTime() > startTime, "Minting is not open yet");
            _mint(msg.sender, id, 1, "");
            mintSupply[msg.sender] += 1;
            supply[id] = supply[id] + 1;
        } else {
            require(
                getCurrentTime() > startTime + 1 hours,
                "Minting is not open yet"
            );
            require(
                mintSupply[msg.sender] < MAX_MINT_SUPPLY_PER_PERSON,
                "You have reached your max claim (1 NFT)"
            );
            _mint(msg.sender, id, 1, "");
            mintSupply[msg.sender] += 1;
            supply[id] = supply[id] + 1;
        }
    }

    function mint(
        address to,
        uint256 id,
        uint256 amount
    ) public onlyOwner {
        require(supply[id] + amount <= MAX_SUPPLY, "Max supply reached");
        _mint(to, id, amount, "");
        supply[id] = supply[id] + amount;
    }

    function setURI(uint256 tokenId, string memory tokenURI) public onlyOwner {
        _setURI(tokenId, tokenURI);
    }

    function batchSetURI(uint256[] memory tokenIds, string[] memory tokenURIs)
        public
        onlyOwner
    {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            _setURI(tokenIds[i], tokenURIs[i]);
        }
    }

    function batchSetMinters(address[] memory _minters) public onlyOwner {
        for (uint256 i = 0; i < _minters.length; i++) {
            minters[_minters[i]] = true;
        }
    }

    function removeMinter(address _minter) public onlyOwner {
        minters[_minter] = false;
    }

    function finishMinting() public onlyOwner {
        mintingFinished = true;
    }

    function getCurrentTime() public view virtual returns (uint256) {
        return block.timestamp;
    }
}