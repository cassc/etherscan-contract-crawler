pragma solidity ^0.8.17;

import "./handlers/ERC20Handler.sol";
import "./helpers/HashIndexer.sol";
import "./interfaces/ISigners.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IERC20MintableBurnable.sol";


contract Bridge is ERC20Handler, HashIndexer, Ownable {
    ISignersRepository public signersRep;

    event DepositERC20(
        string receiver,
        address token,
        uint256 amount,
        string network
    );
    event AdminWithdrawERC20(
        address token,
        address receiver,
        uint256 amount
    );
    event SignersRepoUpdated(address _signersRep, address sender);

    constructor(address _signersRep) Ownable() {
        signersRep = ISignersRepository(_signersRep);
    }

    function checkSignersCopies(address[]memory _signers) private pure returns (bool){
        if (_signers.length == 1) {
            return false;
        }

        for (uint8 i = 0; i < _signers.length - 1; i++) {
            for (uint8 q = i + 1; q < _signers.length; q++) {
                if (_signers[i] == _signers[q]) {
                    return true;
                }
            }
        }

        return false;
    }

    function withdrawERC20(address _token, address _receiver, uint256 _amount) onlyOwner external {
        require(_receiver != address(0), "Zero address recipient specified");
        _sendERC20(_token, _receiver, _amount);
        emit AdminWithdrawERC20(_token, _receiver, _amount);
    }

    function withdrawERC20(
        address _token,
        string memory _txHash,
        uint256 _amount,
        bytes32[] memory _r,
        bytes32[] memory _s,
        uint8[] memory _v
    ) onlyInexistentHash(_txHash) external {
        address[] memory _signers = _deriveERC20Signers(_token, _txHash, _amount, _r, _s, _v);
        checkSigners(_signers);

        _addHash(_txHash);
        _sendERC20(_token, msg.sender, _amount);
    }

    function depositERC20(address _token, string memory _receiver, uint256 _amount, string memory _network) external {
        require(IERC20(_token).transferFrom(msg.sender, address(this), _amount), "token transfer failed");

        emit DepositERC20(_receiver, _token, _amount, _network);
    }
/**
    function burnERC20(address _token, string memory _receiver, uint256 _amount, string memory _network) external {
        require(IERC20MintableBurnable(_token).burnFrom(msg.sender, _amount), "token burn failed");

        emit DepositERC20(_receiver, _token, _amount, _network);
    }

    function mintERC20(
        address _token,
        uint256 _amount,
        string memory _txHash,
        bytes32[] memory _r,
        bytes32[] memory _s,
        uint8[] memory _v
    ) onlyInexistentHash(_txHash) external {
        address[] memory _signers = _deriveERC20Signers(_token, _txHash, _amount, _r, _s, _v);
        checkSigners(_signers);

        _addHash(_txHash);
        require(IERC20MintableBurnable(_token).mint(msg.sender, _amount), "token mint failed");
    }
*/
    function withdrawNative(address _receiver, uint256 _amount) onlyOwner external {
        require(_receiver != address(0), "Zero address recipient specified");
        (bool success,) = _receiver.call{value: _amount}("");
        require(success, "ETH transfer failed");
    }

    function setSignersRep(address _signersRep) external onlyOwner {
        signersRep = ISignersRepository(_signersRep);
        emit SignersRepoUpdated(_signersRep, msg.sender);
    }

    function checkSigners(address[] memory _signers) internal{
        require(
            !checkSignersCopies(_signers),
            "Bridge: signatures contain copies"
        );
        require(
            signersRep.containsSigners(_signers),
            "Bridge: bad signatures"
        );
    }
}