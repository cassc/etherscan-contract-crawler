// MerkleAirdrop.sol

pragma solidity ^0.8.20;

pragma experimental ABIEncoderV2;
import "MerkleProof.sol";
import "IERC20.sol";
import "ERC20.sol";
import "SafeMath.sol";
import "Ownable.sol";
import "UhiveToken.sol";

contract UhiveAirdrop is Ownable {
    using SafeMath for uint256;

    event Claimed(address claimant, uint256 week, uint256 balance);
    event TrancheAdded(uint256 tranche, bytes32 merkleRoot);
    event TrancheExpired(uint256 tranche);
    event RemovedFunder(address indexed _address);
    event TokenTransfer(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

    UhiveToken public _token;
    address _owner;

    mapping(uint256 trancheId => bytes32 merkleRoot) public merkleRoots;
    mapping(uint256 trancheId => mapping(address claimerAddress => bool claimed)) public claimed;

    uint256 public tranches;

    constructor(UhiveToken _HVEtoken) Ownable(msg.sender) {
        _token = _HVEtoken;
        _owner = msg.sender;
    }

    function token() public view virtual returns (UhiveToken) {
        return _token;
    }

    function changeOwner(address _newOwner) onlyOwner public {
        require(_newOwner != address(0), "UhiveAirdrop: Invalid owner address..");
        _owner = _newOwner;
    }

    function addNewTranche(bytes32 _merkleRoot) public onlyOwner returns (uint256 trancheId) {
        trancheId = tranches;
        merkleRoots[trancheId] = _merkleRoot;
        tranches = tranches.add(1);
        emit TrancheAdded(trancheId, _merkleRoot);
    }

    function expireTranche(uint256 _trancheId) public onlyOwner {
        merkleRoots[_trancheId] = bytes32(0);
        emit TrancheExpired(_trancheId);
    }

    function claimTokens(uint256 _tranche, uint256 _balance, bytes32[] memory _merkleProof) public {
        _verifyRequest(msg.sender, _tranche, _balance, _merkleProof);
        uint256 newBalance = _calculateAdditionalBalance(msg.sender, _balance);
        _claimTokens(msg.sender, _tranche, _balance);
        _disburse(msg.sender, newBalance);
    }

    function _verifyRequest(address _address, uint256 _tranche, uint256 _balance, bytes32[] memory _merkleProof) private view {
        require(_tranche < tranches, "UhiveAirdrop: Invalid tranche");
        require(!claimed[_tranche][_address], "UhiveAirdrop: Tokens already claimed");
        require(_verifyClaim(_address, _tranche, _balance, _merkleProof), "UhiveAirdrop: Incorrect merkle proof");
    }

    function verifyClaim(uint256 _tranche, uint256 _balance, bytes32[] memory _merkleProof) public view returns (bool valid) {
        return _verifyClaim(msg.sender, _tranche, _balance, _merkleProof);
    }

    function calculateAirdropTokens(address _address, uint256 _tranche, uint256 _balance, bytes32[] memory _merkleProof) public view returns (uint256 balance) {
        _verifyRequest(_address, _tranche, _balance, _merkleProof);
        return _calculateAdditionalBalance(_address, _balance);
    }

    function _calculateAdditionalBalance(address _address, uint256 _balance) private view returns (uint256 balance) {
        uint256 _walletBalance = _token.balanceOf(_address);
        if(_walletBalance/1 ether < 100000){
            return _balance;
        }
        return _balance * 4;
    }

    function _claimTokens(address _address, uint256 _tranche, uint256 _balance) private {
        claimed[_tranche][_address] = true;
        emit Claimed(_address, _tranche, _balance);
    }

    function _verifyClaim(address _address, uint256 _tranche, uint256 _balance, bytes32[] memory _merkleProof) private view returns (bool valid) {
        bytes32 leaf = keccak256(bytes.concat(keccak256(abi.encode(_address, _balance))));
        return MerkleProof.verify(_merkleProof, merkleRoots[_tranche], leaf);
    }

    function _disburse(address _address, uint256 _balance) private {
        if (_balance > 0) {
            uint256 amount = _balance * (1 ether);
            _token.transfer(_address, amount);
        } else {
            revert("UhiveAirdrop: No balance would be transferred. not going to waste your gas");
        }
    }

    function withdrawTokens() onlyOwner public {
        uint256 vested = _token.balanceOf(address(this));
        if(vested==0){
            revert("UhiveAirdrop: No tokens available to withdraw");
        }
        _deliverTokens(_owner, vested);
    }

     function _deliverTokens(address _beneficiary, uint256 _tokenAmount) internal {
        require(_token.transfer(_beneficiary, _tokenAmount) == true, "UhiveAirdrop: Failed forwarding tokens");
        emit TokenTransfer(msg.sender, _beneficiary, 0, _tokenAmount);
    }
}