// SPDX-License-Identifier: LGPL-3.0

pragma solidity 0.8.17;

import "./interfaces/ILT.sol";
import "./interfaces/IGaugeController.sol";

interface LiquidityGauge {
    function integrateFraction(address addr) external view returns (uint256);

    function userCheckpoint(address addr) external returns (bool);
}

contract Minter {
    event Minted(address indexed recipient, address gauge, uint256 minted);
    event ToogleApproveMint(address sender, address indexed mintingUser, bool status);

    address public immutable token;
    address public immutable controller;

    // user -> gauge -> value
    mapping(address => mapping(address => uint256)) public minted;

    // minter -> user -> can mint?
    mapping(address => mapping(address => bool)) public allowedToMintFor;

    /*
     * @notice Contract constructor
     * @param _token  LT Token Address
     * @param _controller gauge Controller Address
     */
    constructor(address _token, address _controller) {
        token = _token;
        controller = _controller;
    }

    /**
     * @notice Mint everything which belongs to `msg.sender` and send to them
     * @param gaugeAddress `LiquidityGauge` address to get mintable amount from
     */
    function mint(address gaugeAddress) external {
        _mintFor(gaugeAddress, msg.sender);
    }

    /**
     * @notice Mint everything which belongs to `msg.sender` across multiple gauges
     * @param gaugeAddressList List of `LiquidityGauge` addresses
     */
    function mintMany(address[] memory gaugeAddressList) external {
        for (uint256 i = 0; i < gaugeAddressList.length && i < 128; i++) {
            if (gaugeAddressList[i] == address(0)) {
                continue;
            }
            _mintFor(gaugeAddressList[i], msg.sender);
        }
    }

    /**
     * @notice Mint tokens for `_for`
     * @dev Only possible when `msg.sender` has been approved via `toggle_approve_mint`
     * @param gaugeAddress `LiquidityGauge` address to get mintable amount from
     * @param _for Address to mint to
     */
    function mintFor(address gaugeAddress, address _for) external {
        if (allowedToMintFor[msg.sender][_for]) {
            _mintFor(gaugeAddress, _for);
        }
    }

    /**
     * @notice allow `mintingUser` to mint for `msg.sender`
     * @param mintingUser Address to toggle permission for
     */
    function toggleApproveMint(address mintingUser) external {
        bool flag = allowedToMintFor[mintingUser][msg.sender];
        allowedToMintFor[mintingUser][msg.sender] = !flag;
        emit ToogleApproveMint(msg.sender, mintingUser, !flag);
    }

    function _mintFor(address gaugeAddr, address _for) internal {
        ///Gomnoc not adde
        require(IGaugeController(controller).gaugeTypes(gaugeAddr) >= 0, "CE000");

        bool success = LiquidityGauge(gaugeAddr).userCheckpoint(_for);
        require(success, "CHECK FAILED");
        uint256 totalMint = LiquidityGauge(gaugeAddr).integrateFraction(_for);
        uint256 toMint = totalMint - minted[_for][gaugeAddr];

        if (toMint != 0) {
            minted[_for][gaugeAddr] = totalMint;
            bool success = ILT(token).mint(_for, toMint);
            require(success, "MINT FAILED");
            emit Minted(_for, gaugeAddr, toMint);
        }
    }
}