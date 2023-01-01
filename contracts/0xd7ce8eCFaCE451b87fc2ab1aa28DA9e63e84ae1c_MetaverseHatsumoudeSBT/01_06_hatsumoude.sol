// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0 <0.9.0;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract MetaverseHatsumoudeSBT is ERC721A, Ownable, Pausable {
    address public constant withdrawAddress = 0x79c1eDa948Bb6a50E6b88C761CD01133b7350B3A;
    string public baseURI;
    string public baseExtension;
    uint256 public mintCost = 0.003 ether;
    uint256 public maxSupply = 2222;
    mapping(address => uint256) mintedAmount;

    // Constructor
    constructor() ERC721A("MetaverseHatsumoudeSBT", "MHSBT") {
        _pause();
    }

    // Modifier
    modifier enoughEth(uint256 amount) {
        require(msg.value >= amount * mintCost, 'Not Enough Eth');
        _;
    }
    modifier withinMaxSupply(uint256 amount) {
        require(totalSupply() + amount <= maxSupply, 'Over Max Supply');
        _;
    }
    modifier doNotHave() {
        require(mintedAmount[msg.sender] == 0, 'Already Minted');
        _;
    }

    // Pausable
    function pause() external onlyOwner {
        _pause();
    }
    function unpause() external onlyOwner {
        _unpause();
    }

    // Getter
    function getMintedAmount(address targetAddress) view public returns(uint256) {
        return mintedAmount[targetAddress];
    }

    // Setter
    function setMaxSupply(uint256 _value) public onlyOwner {
        maxSupply = _value;
    }
    function setMintCost(uint256 _value) public onlyOwner {
        mintCost = _value;
    }
    function setBaseURI(string memory _value) external onlyOwner {
        baseURI = _value;
    }
    function setBaseExtension(string memory _value) external onlyOwner {
        baseExtension = _value;
    }
    function resetBaseExtension() external onlyOwner {
        baseExtension = "";
    }

    // AirDrop
    function airdrop(address[] calldata addresses) external onlyOwner
        withinMaxSupply(addresses.length)
    {
        for (uint256 i = 0; i < addresses.length; i++) {
            require(mintedAmount[addresses[i]] == 0, 'Already minted');
            mintedAmount[addresses[i]] += 1;
            _safeMint(addresses[i], 1);
        }
    }

    // Mint
    function mint() external payable
        whenNotPaused
        enoughEth(1)
        doNotHave()
    {
        mintedAmount[msg.sender] += 1;
        _safeMint(msg.sender, 1);
    }

    // For ERC721A
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        return string(abi.encodePacked(ERC721A.tokenURI(tokenId), baseExtension));
    }
    function exists(uint256 tokenId) public view virtual returns (bool) {
        return _exists(tokenId);
    }
    function withdraw() public payable onlyOwner {
        (bool os, ) = payable(withdrawAddress).call{value: address(this).balance}("");
        require(os);
    }

    // For SBT
    function setApprovalForAll(address, bool) public virtual override {
        revert("This token is SBT.");
    }
    function approve(address, uint256) public virtual override payable {
        revert("This token is SBT.");
    }
    function _beforeTokenTransfers(address from, address to, uint256, uint256) internal virtual override {
        require(from == address(0) || to == address(0), "This token is SBT");
    }
}