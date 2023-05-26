// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.17;
import "./Ownable.sol";
import "./IERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

interface IesLBR {
    function mint(address user, uint256 amount) external returns(bool);
}
contract PublicSale is Ownable {
    uint256 public lbrPerEther = 20000;
    address public lbr;
    IesLBR public esLBR;
    uint256 public startTime;
    uint256 public endTime;
    uint256 public claimTime;
    uint256 public softcap = 100 ether;
    uint256 public hardcap = 250 ether;
    bool public softcapmet;
    bytes32 public root;
    address public multisignature;

    mapping (address => uint256) public payAmount;

    constructor(address _lbr,address _eslbr, uint256 _start, uint256 _end,uint256 _claimTime, address _multisignature) {
        lbr = _lbr;
        esLBR = IesLBR(_eslbr);
        startTime = _start;
        endTime = _end;
        claimTime = _claimTime;
        multisignature = _multisignature;
    }

    modifier isValidMerkleProof(bytes32[] calldata merkleProof) {
        require(
            MerkleProof.verifyCalldata(
                merkleProof,
                root,
                keccak256(abi.encodePacked(msg.sender))
            ),
            "The address is not on the whitelist."
        );
        _;
    }

    /**
     * @dev Allows owner to adjust the merkle root hash.
     */
    function setMerkleRoot(bytes32 _root) external onlyOwner {
        root = _root;
    }

    function setPrice(uint256 _price) external onlyOwner {
        require(block.timestamp < startTime, "IDO has started, the price cannot be changed");
        lbrPerEther = _price;
    }

    function setTime(uint256 _start, uint256 _end) external onlyOwner {
        if(startTime > 0) {
            require(block.timestamp < startTime);
        }
        startTime = _start;
        endTime = _end;
    }

    function join() external payable {
        require(block.timestamp >= startTime && block.timestamp < endTime, "The public sale hasn't started yet");
        require(address(this).balance <= hardcap, "IDO quota has been reached");
        payAmount[msg.sender] += msg.value;
        if(address(this).balance >= softcap) {
            softcapmet = true;
        }
    }

    function leave(uint256 amount) external {
        require(!softcapmet, "Refunds are not possible as the soft cap has been exceeded");
        require(payAmount[msg.sender] >= amount, "The exit amount is greater than the invested amount");
        payAmount[msg.sender] -= amount;
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Transfer failed.");
    }

    function getReward() external view returns(uint256) {
        return payAmount[msg.sender] * lbrPerEther;
    }

    function mint() external {
        require(block.timestamp >= claimTime, "LBR can only be claimed after the claimTime");
        require(softcapmet, "LBR cannot be claimed as the soft cap for IDO has not been reached");
        uint256 amount = payAmount[msg.sender];
        payAmount[msg.sender] = 0;
        IERC20(lbr).transfer(msg.sender, amount * lbrPerEther);
    }

    function whiteListMint(bytes32[] calldata merkleProof) external isValidMerkleProof(merkleProof) {
        require(block.timestamp >= claimTime, "LBR can only be claimed after the claimTime");
        require(softcapmet, "LBR cannot be claimed as the soft cap for IDO has not been reached");
        uint256 amount = payAmount[msg.sender];
        payAmount[msg.sender] = 0;
        IERC20(lbr).transfer(msg.sender, amount * lbrPerEther);
        esLBR.mint(msg.sender, amount * lbrPerEther / 10);
    }

    function withdrawEther() external onlyOwner {
        require(block.timestamp >= endTime, "The owner can only withdraw ETH after the IDO ends");
        require(softcapmet, "The owner cannot withdraw ETH as the soft cap for IDO has not been reached");
        (bool success, ) = multisignature.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    // to help users who accidentally send their tokens to this contract
    function sendToken(address token, address to, uint256 amount) external onlyOwner {
        require(block.timestamp >= endTime);
        IERC20(token).transfer(to, amount);
    }
}