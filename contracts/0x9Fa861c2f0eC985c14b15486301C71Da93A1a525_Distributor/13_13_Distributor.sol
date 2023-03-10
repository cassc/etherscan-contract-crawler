// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {Address} from "openzeppelin-contracts/utils/Address.sol";
import {IERC20} from "openzeppelin-contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "openzeppelin-contracts/token/ERC20/utils/SafeERC20.sol";

import {Clonable} from "bunny-libs/Clonable/Clonable.sol";
import {MembershipToken} from "bunny-libs/MembershipToken/MembershipToken.sol";

contract Distributor is MembershipToken, Clonable {
    using SafeERC20 for IERC20;
    using Address for address payable;

    //********//
    // Types //
    //*******//

    event Distributed();
    event Deposited(address from, uint256 amount);

    struct Outflow {
        address destination;
        uint256 amount;
    }

    //***********//
    // Variables //
    //***********//

    /// Contract version
    uint256 public constant CONTRACT_VERSION = 2_00;

    /// Maximum token amount that can be distributed at once.
    /// This is to avoid overflows when calculating member shares.
    uint224 constant MAX_DISTRIBUTION_AMOUNT = type(uint224).max;

    //****************//
    // Initialization //
    //****************//

    constructor(
        string memory name_,
        string memory symbol_,
        Membership[] memory members_,
        CloningConfig memory cloningConfig
    ) initializer Clonable(cloningConfig) {
        _initialize(encodeInitdata(name_, symbol_, members_));
    }

    /**
     * Initialize the contract.
     * @param initdata Contract initialization data, encoded as bytes.
     */
    function _initialize(bytes memory initdata) internal override {
        (string memory name_, string memory symbol_, Membership[] memory members_) = decodeInitdata(initdata);
        MembershipToken._initialize(name_, symbol_, members_);
    }

    /**
     * Helper for encoding initialization parameters to bytes.
     * @param name_ Token name.
     * @param symbol_ Token symbol.
     * @param members_ Memberships to mint.
     */
    function encodeInitdata(string memory name_, string memory symbol_, Membership[] memory members_)
        public
        pure
        returns (bytes memory)
    {
        return abi.encode(name_, symbol_, members_);
    }

    /**
     * Helper for decoding initialization parameters from bytes.
     * @param initdata Initialization data, encoded to bytes.
     */
    function decodeInitdata(bytes memory initdata)
        public
        pure
        returns (string memory, string memory, Membership[] memory)
    {
        return abi.decode(initdata, (string, string, Membership[]));
    }

    //****************//
    // Member actions //
    //****************//

    /**
     * Distribute a specific amount of an ERC20 token at an address to members.
     * @dev Needs token approval. Capped to uint224 at a time to avoid overflow.
     * @param asset The token that should be distributed.
     * @param source The address that we should distribute from.
     * @param amount The amount that should be distributed.
     */
    function distribute(address asset, address source, uint256 amount) external memberOnly {
        _distribute(IERC20(asset), source, amount);
    }

    /**
     * Distribute the full balance of an ERC20 token at an address to members.
     * @dev Needs token approval. Capped to uint224 at a time to avoid overflow.
     * @param asset The token that should be distributed.
     * @param source The address that we should distribute from.
     */
    function distribute(address asset, address source) external memberOnly {
        IERC20 token = IERC20(asset);
        _distribute(token, source, token.balanceOf(source));
    }

    /**
     * Distribute the full native token balance of this contract to members.
     * @dev Payable so native token can be supplied when called.
     */
    function distribute() external payable memberOnly {
        Outflow[] memory outflows = _generateOutflows(address(this).balance);

        for (uint256 i = 0; i < outflows.length; i++) {
            Outflow memory outflow = outflows[i];
            payable(outflow.destination).sendValue(outflow.amount);
        }

        emit Distributed();
    }

    //*************//
    // Simulations //
    //*************//

    /**
     * Simulate the distribution of an arbitrary amount.
     * @param amount The amount to be distributed.
     */
    function simulate(uint256 amount) external view returns (Outflow[] memory) {
        return _generateOutflows(amount);
    }

    //***********//
    // Internals //
    //***********//

    /**
     * Generate outflows based on current membership distribution and an amount of tokens.
     * @param totalTokens The total amount of tokens that should be distributed.
     */
    function _generateOutflows(uint256 totalTokens) internal view returns (Outflow[] memory) {
        uint256 totalMemberships = totalSupply;
        Outflow[] memory outflows = new Outflow[](totalMemberships);

        uint224 distributionAmount =
            totalTokens <= MAX_DISTRIBUTION_AMOUNT ? uint224(totalTokens) : MAX_DISTRIBUTION_AMOUNT;

        for (uint256 tokenId = 0; tokenId < totalMemberships; tokenId++) {
            outflows[tokenId].destination = ownerOf(tokenId);
            outflows[tokenId].amount = tokenShare(tokenId, distributionAmount);
        }

        return outflows;
    }

    /**
     * Distribute the specified amount of ERC20 tokens from the source address.
     * @param token The token that should be distributed.
     * @param source The address that we should distribute from.
     * @param amount The amount that should be distributed.
     */
    function _distribute(IERC20 token, address source, uint256 amount) internal {
        Outflow[] memory outflows = _generateOutflows(amount);

        if (source == address(this)) {
            for (uint256 i = 0; i < outflows.length; i++) {
                token.safeTransfer(outflows[i].destination, outflows[i].amount);
            }
        } else {
            for (uint256 i = 0; i < outflows.length; i++) {
                token.safeTransferFrom(source, outflows[i].destination, outflows[i].amount);
            }
        }

        emit Distributed();
    }

    /**
     * Fallback function to support direct payments to the contract address.
     */
    fallback() external payable {
        emit Deposited(msg.sender, msg.value);
    }
}