// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract NPassport is AccessControl, ERC721, Ownable, Pausable {
    bytes32 public constant ADMIN = "ADMIN";
    uint256 public subscribeTermSec = 180 days;

    address public withdrawAddress;
    string public baseURI;
    string public baseExtension;
    bytes32 merkleRoot;
    uint256 public totalSupply = 0;

    // Plan
    uint8 public planNoForPublic;
    uint8 public planNoForAllowlist;
    mapping(uint8 => uint256) public planCosts;

    // PassportInfo
    struct PassportInfo {
        uint256 tokenId;
        uint8 planNo;
        uint256 expiredTimestamp;
    }
    mapping(address => PassportInfo) passportInfoByAddress;

    // Constructor
    constructor(string memory _name, string memory _symbol, address _withdrawAddress) ERC721(_name, _symbol) {
        grantRole(ADMIN, msg.sender);
        withdrawAddress = _withdrawAddress;
    }

    // Event
    event Subscribe(uint256 _tokenId, address _owner, uint8 _planNo, uint256 _value);

    // Modifier
    modifier existsPlan(uint8 planNo) {
        require(planCosts[planNo] > 0, 'Sale Plan Does Not Exist');
        _;
    }
    modifier enoughEth(uint8 planNo) {
        require(msg.value >= planCosts[planNo] , 'Not Enough Eth');
        _;
    }
    modifier doNotHave() {
        require(balanceOf(msg.sender) == 0, 'Already Minted');
        _;
    }
    modifier isTokenOwner(uint256 tokenId) {
        require(ownerOf(tokenId) == msg.sender, "You Are Not Token Owner");
        _;
    }
    modifier isValidProof(bytes32[] calldata merkleProof) {
        bytes32 node = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verifyCalldata(merkleProof, merkleRoot, node), "Invalid proof");
        _;
    }
    modifier existsPassportInfo(address owner) {
        require(passportInfoByAddress[owner].tokenId > 0, "Passport Info Does Not Exist");
        _;
    }

    // AccessControl
    function grantRole(bytes32 role, address account) public override onlyOwner {
        _grantRole(role, account);
    }
    function revokeRole(bytes32 role, address account) public override onlyOwner {
        _revokeRole(role, account);
    }

    // Pausable
    function pause() external onlyRole(ADMIN) {
        _pause();
    }
    function unpause() external onlyRole(ADMIN) {
        _unpause();
    }

    // Getter
    function getMintCostForPublic() public view returns(uint256) {
        return planCosts[planNoForPublic];
    }
    function getMintCostForAllowlist() public view returns(uint256) {
        return planCosts[planNoForAllowlist];
    }
    function getMintCostForSubscribe(address owner) public view returns(uint256) {
        return planCosts[passportInfoByAddress[owner].planNo];
    }
    function getPassportInfo(address owner) view public returns(PassportInfo memory) {
        return passportInfoByAddress[owner];
    }
    function passportIsValid(address owner) view public returns(bool) {
        return passportInfoByAddress[owner].expiredTimestamp >= block.timestamp;
    }

    // Setter
    function setWithdrawAddress(address _value) public onlyRole(ADMIN) {
        withdrawAddress = _value;
    }
    function setPlanNoForPublic(uint8 _value) public onlyRole(ADMIN) {
        planNoForPublic = _value;
    }
    function setPlanNoForAllowlist(uint8 _value) public onlyRole(ADMIN) {
        planNoForAllowlist = _value;
    }
    function setMintCost(uint8 _planNo, uint256 _cost) public onlyRole(ADMIN) {
        planCosts[_planNo] = _cost;
    }
    function setMerkleRoot(bytes32 _value) public onlyRole(ADMIN) {
        merkleRoot = _value;
    }
    function setSubscribeTermSec(uint256 _value) external onlyRole(ADMIN) {
        subscribeTermSec = _value;
    }
    function setBaseURI(string memory _value) external onlyRole(ADMIN) {
        baseURI = _value;
    }
    function setBaseExtension(string memory _value) external onlyRole(ADMIN) {
        baseExtension = _value;
    }
    function resetBaseExtension() external onlyRole(ADMIN) {
        baseExtension = "";
    }
    function resetExpiredTimestamp(address owner) external onlyRole(ADMIN)
        existsPassportInfo(owner)
    {
        passportInfoByAddress[owner].expiredTimestamp = block.timestamp - 1;
    }

    // Mint
    function mint() external payable
        whenNotPaused
        doNotHave()
        enoughEth(planNoForPublic)
    {
        _mintCommon(msg.sender, planNoForPublic);
    }
    function allowlistMint(bytes32[] calldata merkleProof) external payable
        whenNotPaused
        doNotHave()
        enoughEth(planNoForAllowlist)
        isValidProof(merkleProof)
    {
        _mintCommon(msg.sender, planNoForAllowlist);
    }
    function airdrop(address[] calldata addresses, uint8 planNo) external onlyRole(ADMIN) {
        for (uint256 i = 0; i < addresses.length; i++) {
            if (balanceOf(addresses[i]) == 0) {
                _mintCommon(addresses[i], planNo);
            }
        }
    }
    function _mintCommon(address mintTo, uint8 planNo) private
        existsPlan(planNo)
    {
        uint256 tokenId = totalSupply + 1;
        _safeMint(mintTo, tokenId);
        totalSupply++;
        passportInfoByAddress[mintTo] = PassportInfo(
            tokenId,
            planNo,
            block.timestamp + subscribeTermSec
        );
    }

    // Subscribe
    function subscribe() external payable
        existsPassportInfo(msg.sender)
    {
        if (passportInfoByAddress[msg.sender].expiredTimestamp > block.timestamp) {
            require(msg.value >= planCosts[passportInfoByAddress[msg.sender].planNo] , 'Not Enough Eth');
            passportInfoByAddress[msg.sender].expiredTimestamp += subscribeTermSec;
        } else {
            require(msg.value >= planCosts[planNoForPublic] , 'Not Enough Eth');
            passportInfoByAddress[msg.sender].expiredTimestamp = block.timestamp + subscribeTermSec;
            passportInfoByAddress[msg.sender].planNo = planNoForPublic;
        }
        emit Subscribe(passportInfoByAddress[msg.sender].tokenId, msg.sender, passportInfoByAddress[msg.sender].planNo, msg.value);
    }

    // ERC721
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        return string(abi.encodePacked(baseURI, Strings.toString(tokenId), baseExtension));
    }
    function exists(uint256 tokenId) public view virtual returns (bool) {
        return _exists(tokenId);
    }
    function withdraw() public payable onlyRole(ADMIN) {
        (bool os, ) = payable(withdrawAddress).call{value: address(this).balance}("");
        require(os);
    }

    // SBT
    function setApprovalForAll(address, bool) public virtual override {
        revert("This token is SBT.");
    }
    function approve(address, uint256) public virtual override {
        revert("This token is SBT.");
    }
    function _beforeTokenTransfer(address from, address to, uint256) internal virtual override {
        require(from == address(0) || to == address(0), "This token is SBT");
    }

    // interface
    function supportsInterface(bytes4 interfaceId) public view virtual override(AccessControl, ERC721) returns (bool) {
        return
            ERC721.supportsInterface(interfaceId) ||
            AccessControl.supportsInterface(interfaceId);
    }
}