// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract BunnyBuddiesMembership is ERC1155, Ownable {
    using Strings for uint256;

    // maxSupply[0] -> gold / maxSupply[1] -> platinum / maxSupply[2] -> diamond /
    mapping(uint256 => uint256) public maxSupply;

    mapping(uint256 => uint256) public totalSupplyReached;

    mapping(address => mapping(uint256 => uint256)) public balanceByType;

    mapping(address => bool) public isClaim;

    // workflow : 0 -> closed or airdrop / 1 -> gold claim / 2 -> platinum claim / -> 3 diamond claim
    uint256 public workflow = 0;

    uint256 public goldBurn = 8;

    uint256 public platinumBurn = 2;

    bytes32 public merkleRoot;

    string public baseURI;

    string public _name = 'BunnyBuddiesMembership';

    string public _symbol = 'BBM';

    constructor() ERC1155("") {
          maxSupply[0] = 8888;
          maxSupply[1] = 555;
          maxSupply[2] = 111;
    }

    event ChangeBaseURI(string _baseURI);
    event GoldClaim(address indexed _minter, uint256 _amount);
    event PlatinumMint(address indexed _minter, uint256 _amount);
    event DiamondMint(address indexed _minter, uint256 _amount);

    function _checkFreeAmount(uint256 amount, bytes32[] calldata proof) internal view returns(bool)  {
        require(MerkleProof.verify(proof, merkleRoot, keccak256(abi.encode(msg.sender, amount))));
        return true;
    }

    function goldAirdrop(address[] memory _walletAddress, uint256[] memory _nftToClaim) external onlyOwner {

        uint256 lthWallet = _walletAddress.length;
        uint256 lthNft = _nftToClaim.length;

        require(lthWallet == lthNft, "Arrays have not same length!");

        for (uint256 i = 0; i < lthWallet; ++i) {
            _mint(_walletAddress[i],0, _nftToClaim[i], "");
            balanceByType[_walletAddress[i]][0] += _nftToClaim[i];
            totalSupplyReached[0] += _nftToClaim[i];
        }
    }

    function goldClaim(uint256 amount, bytes32[] calldata _merkleProof)
        public
    {
        require(workflow == 1, "Claim : gold claim not open");
        require(totalSupplyReached[0] + amount <= maxSupply[0], "Max golden card supply limite");
        require(!isClaim[address(msg.sender)], "already claimed");

        bool access = _checkFreeAmount(amount, _merkleProof);
        require(access);

        _mint(address(msg.sender), 0, amount, "");
        balanceByType[address(msg.sender)][0] += amount;
        totalSupplyReached[0] += amount;

        isClaim[address(msg.sender)] = true;
        emit GoldClaim(msg.sender, amount);
    }

    function platinumMint(uint256 amount)
        public
    {
        require(workflow == 2, "Claim : platinum Mint not open");
        require(totalSupplyReached[1] + amount <= maxSupply[1], "Max platinum card supply limite");

        uint256 toBurn = amount * goldBurn;
        require(balanceByType[address(msg.sender)][0] >= toBurn);

        _burn(address(msg.sender), 0, amount * goldBurn);

        if (balanceByType[address(msg.sender)][0] >= toBurn) {
        balanceByType[address(msg.sender)][0] -= toBurn;
        } else {
        balanceByType[address(msg.sender)][0] = 0;
        }

        _mint(address(msg.sender), 1, amount, "");
        balanceByType[address(msg.sender)][1] += amount;
        totalSupplyReached[1] += amount;

        emit PlatinumMint(msg.sender, amount);
    }

    function diamondMint(uint256 amount)
        public
    {
        require(workflow == 3, "Claim : diamond Mint not open");
        require(totalSupplyReached[2] + amount <= maxSupply[2], "Max diamond card supply limite");

        uint256 toBurn = amount * platinumBurn;
        require(balanceByType[address(msg.sender)][1] >= toBurn);

        _burn(address(msg.sender), 1, toBurn);

        if (balanceByType[address(msg.sender)][1] >= toBurn) {
        balanceByType[address(msg.sender)][1] -= toBurn;
        } else {
        balanceByType[address(msg.sender)][1] = 0;
        }

        _mint(address(msg.sender), 2, amount, "");
        balanceByType[address(msg.sender)][2] += amount;
        totalSupplyReached[2] += amount;

        emit DiamondMint(msg.sender, amount);
    }


    function uri(uint256 _id)
        public
        view
        virtual
        override
        returns (string memory)
    {
        return string(abi.encodePacked(baseURI, _id.toString(), ".json"));
    }

    //-----------NFT MANAGEMENT-------------//

    function updateSupply(uint256 goldSupply, uint256 platinumSupply, uint256 diamondSupply)
        external
        onlyOwner
    {
        maxSupply[0] = goldSupply;
        maxSupply[1] = platinumSupply;
        maxSupply[2] = diamondSupply;
    }

    function getSupply(uint256 tokenID)
        external
        view
        returns (uint256)
    {
        return maxSupply[tokenID];
    }

    function updateBurnAmount(uint256 _goldBurn, uint256 _platinumBurn)
        external
        onlyOwner
    {
        goldBurn = _goldBurn;
        platinumBurn = _platinumBurn;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    //----------WORKFLOW MANAGEMENT-----------//
    function close() external onlyOwner {
        workflow = 0;
    }

    function setUpGoldClaim() external onlyOwner {
        workflow = 1;
    }

    function setUpPlatinumClaim() external onlyOwner {
        workflow = 2;
    }

    function setUpDiamondClaim() external onlyOwner {
        workflow = 3;
    }

    function getSaleStatus() public view returns (uint256) {
        return workflow;
    }

    //-----------MERKLE MANAGEMENT-------------//

    function setMerkleRoot(bytes32 root) public onlyOwner {
        merkleRoot = root;
    }

    //---------------- OTHER ----------------//

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(address(owner())).transfer(
            balance
        );
    }

    function name() external view returns (string memory) {
        return _name;
    }

    function symbol() external view returns (string memory) {
        return _symbol;
    }
}