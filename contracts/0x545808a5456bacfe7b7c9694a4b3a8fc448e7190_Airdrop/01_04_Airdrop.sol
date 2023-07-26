pragma solidity ^0.6.6;
pragma experimental ABIEncoderV2;
import "./Vendor.sol";
import "./Initializable.sol";

contract Airdrop is Ownable , Initializable {
    using SafeERC20 for IERC20;
    IERC20 public token;
    mapping(address => uint256) public claimed;
    uint256 public claimAmount;
    bool public isOpen;
    bytes32 public merkleRoot;
    uint256 public totalClaims;
    uint256 public stageQuantity;
    uint256 public maxStage;

    event Claim(address to, uint256 amount, address inviter);
    //0x0000000000000000000000000000000000000000000000000000000000000000
    function initialize(IERC20 _token, uint256 _claimAmount, uint256 _stageQuantity, uint256 _maxStage, bytes32 _merkleRoot) public initializer {
        token = _token;
        isOpen = false;
        merkleRoot = _merkleRoot;
        claimAmount = _claimAmount;
        stageQuantity = _stageQuantity;
        maxStage = _maxStage;
        _owner = msg.sender;
    }

    function claim(address inviterAddr, bytes32[] memory merkleProof) public {
        require(isOpen, "Airdrop is closed");
        require(claimed[msg.sender] == 0, "Already claimed");
        if (merkleRoot != bytes32(0)) {
            require(verifyMerkle(msg.sender, merkleProof), "Not eligible for airdrop");
        }
        uint256 newClaimAmount = getClaimAmount();
        uint256 remainingAmount = token.balanceOf(address(this));
        require(remainingAmount > newClaimAmount || currentStage() <= maxStage, "Airdrop has ended");
        uint256 inviterRewardAmount = newClaimAmount / 10;
        token.safeTransfer(msg.sender, newClaimAmount - inviterRewardAmount);
        claimed[msg.sender] = newClaimAmount - inviterRewardAmount;
        if(inviterAddr != address(0)) {
            token.safeTransfer(inviterAddr, inviterRewardAmount);
        }
        
        emit Claim(msg.sender, newClaimAmount - inviterRewardAmount, inviterAddr);
        totalClaims++;
    }

    function currentStage() public view returns(uint256) {
        return totalClaims / stageQuantity;
    }

    function getClaimAmount() private view returns(uint256 newClaimAmount) {
        newClaimAmount = claimAmount;
        for(uint256 i = 0; i < currentStage(); i++) {
            newClaimAmount = newClaimAmount - (newClaimAmount / 10);
        }
    }

    function currentClaimAmount() public view returns(uint256 newClaimAmount) {
        newClaimAmount = claimAmount;
        for(uint256 i = 0; i <= currentStage(); i++) {
            newClaimAmount = newClaimAmount - (newClaimAmount / 10);
        }
    }
    
    function updateMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function updateStageQuantity(uint256 _stageQuantity) public onlyOwner {
        stageQuantity = _stageQuantity;
    }

    function updateClaimAmount(uint256 _claimAmount) public onlyOwner {
        claimAmount = _claimAmount;
    }

    function updateMaxStage(uint256 _maxStage) public onlyOwner {
        maxStage = _maxStage;
    }

    function open() public onlyOwner {
        isOpen = true;
    }

    function close() public onlyOwner {
        isOpen = false;
    }

    function verifyMerkle(address addr, bytes32[] memory merkleProof) public view returns(bool) {
        bytes32 leaf = keccak256(abi.encodePacked(addr));
        return MerkleProof.verify(merkleProof, merkleRoot, leaf);
    }
    
    function retrieveToken(address token_, address to, uint256 amount) public onlyOwner {
		IERC20 coin = IERC20(token_);
		coin.safeApprove(address(this), amount);
		coin.safeTransfer(to, amount);
	}
}