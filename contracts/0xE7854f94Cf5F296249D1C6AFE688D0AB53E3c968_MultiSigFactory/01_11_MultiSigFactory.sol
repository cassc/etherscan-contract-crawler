// SPDX-License-Identifier:  CC-BY-NC-4.0
// email "licensing [at] pyxelchain.com" for licensing information
pragma solidity =0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "./MultiSig.sol";

contract MultiSigFactory is Ownable {
    using Address for address;
    using Clones for address;
    using SafeERC20 for IERC20;

    event CreateMultiSigInstance(address instance);

    /**
     * @dev Deploys and emits address of a clone at a random address with same behaviour of `implementation`
     * @dev Any funds sent to this function will be forwarded to the clone, and thus it must be initialized
     */
    function clone(
        address implementation,
        bytes calldata initdata
    ) public payable {
        address instance = implementation.clone();
        require(msg.value == 0 || initdata.length > 0, "MSF: prefund without init");
        if (initdata.length > 0) {
            instance.functionCallWithValue(initdata, msg.value); // initialize (required if prefunding)
        }
        emit CreateMultiSigInstance(instance);
    }

    /**
     * @dev Deploys and emits address of a clone at a deterministic address with same behaviour of `implementation`
     * @dev Any funds sent to this function will be forwarded to the clone, and thus it must be initialized
     */
    function cloneDeterministic(
        address implementation,
        bytes32 salt,
        bytes calldata initdata
    ) public payable {
        address instance = implementation.cloneDeterministic(salt);
        require(msg.value == 0 || initdata.length > 0, "MSF: prefund without init");
        if (initdata.length > 0) {
            instance.functionCallWithValue(initdata, msg.value); // initialize (required if prefunding)
        }
        emit CreateMultiSigInstance(instance);
    }

    /**
     * @dev Computes the address of a clone deployed using `cloneDeterministic`
     */
    function predictDeterministicAddress(address implementation, bytes32 salt) public view returns (address predicted) {
        return implementation.predictDeterministicAddress(salt);
    }

    //// BOILERPLATE

    /**
     * @notice receive ETH with no calldata
     * @dev see: https://blog.soliditylang.org/2020/03/26/fallback-receive-split/
     */
    // solhint-disable-next-line no-empty-blocks
    receive() external payable {}

    /**
     * @notice receive ETH with no function match
     */
    fallback() external payable {}

    /**
     * @notice allow withdraw of any ETH sent directly to the contract
     */
    function withdraw() external onlyOwner {
        address payable owner = payable(owner());
        owner.transfer(address(this).balance);
    }

    /**
     * @notice allow withdraw of any ERC20 sent directly to the contract
     * @param _token the address of the token to use for withdraw
     * @param _amount the amount of the token to withdraw
     */
    function withdrawToken(address _token, uint _amount) external onlyOwner {
        IERC20(_token).safeTransfer(owner(), _amount);
    }
}