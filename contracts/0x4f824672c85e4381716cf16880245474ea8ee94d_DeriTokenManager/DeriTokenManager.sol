/**
 *Submitted for verification at Etherscan.io on 2023-06-24
*/

// File: contracts/utils/IAdmin.sol



pragma solidity >=0.8.0 <0.9.0;

interface IAdmin {

    event NewAdmin(address indexed newAdmin);

    function admin() external view returns (address);

    function setAdmin(address newAdmin) external;

}

// File: contracts/utils/Admin.sol



pragma solidity >=0.8.0 <0.9.0;


abstract contract Admin is IAdmin {

    address public admin;

    modifier _onlyAdmin_() {
        require(msg.sender == admin, 'Admin: only admin');
        _;
    }

    constructor () {
        admin = msg.sender;
        emit NewAdmin(admin);
    }

    function setAdmin(address newAdmin) external _onlyAdmin_ {
        admin = newAdmin;
        emit NewAdmin(newAdmin);
    }

}

// File: contracts/token/IERC20.sol



pragma solidity >=0.8.0 <0.9.0;

interface IERC20 {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 amount
    );

    event Transfer(address indexed from, address indexed to, uint256 amount);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transfer(address to, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    function mint(
        address account,
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function mint(address account, uint256 amount) external;
}

// File: contracts/interface/IWormhole.sol

pragma solidity >=0.8.0 <0.9.0;


interface IWormhole {
    function freeze(
        uint256 amount,
        uint256 toChainId,
        address toWormhole
    ) external;

    function claim(
        uint256 amount,
        uint256 fromChainId,
        address fromWormhole,
        uint256 fromNonce,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

// File: contracts/interface/IZksyncL1ERC20Bridge.sol

pragma solidity >=0.8.0 <0.9.0;


/// @author Matter Labs
interface IZksyncL1ERC20Bridge {
    function deposit(
        address _l2Receiver,
        address _l1Token,
        uint256 _amount,
        uint256 _l2TxGasLimit,
        uint256 _l2TxGasPerPubdataByte
    ) external payable returns (bytes32 txHash);

    function deposit(
        address _l2Receiver,
        address _l1Token,
        uint256 _amount,
        uint256 _l2TxGasLimit,
        uint256 _l2TxGasPerPubdataByte,
        address _refundRecipient
    ) external payable returns (bytes32 txHash);
}

// File: contracts/interface/IArbitrumTokenGateway.sol



/*
 * Copyright 2020, Offchain Labs, Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

// solhint-disable-next-line compiler-version
pragma solidity >=0.6.9 <0.9.0;

interface IArbitrumTokenGateway {
    /// @notice event deprecated in favor of DepositInitiated and WithdrawalInitiated
    // event OutboundTransferInitiated(
    //     address token,
    //     address indexed _from,
    //     address indexed _to,
    //     uint256 indexed _transferId,
    //     uint256 _amount,
    //     bytes _data
    // );

    /// @notice event deprecated in favor of DepositFinalized and WithdrawalFinalized
    // event InboundTransferFinalized(
    //     address token,
    //     address indexed _from,
    //     address indexed _to,
    //     uint256 indexed _transferId,
    //     uint256 _amount,
    //     bytes _data
    // );

    function outboundTransfer(
        address _token,
        address _to,
        uint256 _amount,
        uint256 _maxGas,
        uint256 _gasPriceBid,
        bytes calldata _data
    ) external payable returns (bytes memory);

    function finalizeInboundTransfer(
        address _token,
        address _from,
        address _to,
        uint256 _amount,
        bytes calldata _data
    ) external payable;

    /**
     * @notice Calculate the address used when bridging an ERC20 token
     * @dev the L1 and L2 address oracles may not always be in sync.
     * For example, a custom token may have been registered but not deploy or the contract self destructed.
     * @param l1ERC20 address of L1 token
     * @return L2 address of a bridged ERC20 token
     */
    function calculateL2TokenAddress(
        address l1ERC20
    ) external view returns (address);

    function getOutboundCalldata(
        address _token,
        address _from,
        address _to,
        uint256 _amount,
        bytes memory _data
    ) external view returns (bytes memory);
}

// File: contracts/DeriTokenManagerMainnet.sol


pragma solidity >=0.8.0 <0.9.0;






contract DeriTokenManager is Admin {
    struct Signature {
        uint256 amount;
        uint256 deadline;
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    struct CrossChainDetails {
        bool isArbitrum;
        uint256 poolId;
        address _token;
        address _to;
        uint256 _maxGas;
        uint256 _gasPriceBid;
        uint256 _value;
        bytes _data;
        address _l2Receiver;
        address _l1Token;
        uint256 _l2TxGasLimit;
        uint256 _l2TxGasPerPubdataByte;
        address _refundRecipient;
    }

    // poolId => rewardPerSeconds
    // 0 -> Arbitrum RewardVault V2
    // 1 -> Arbitrum Uniswap
    // 2 -> Zksync RewardVault V2
    // 3 -> BNB RewardVault V2
    mapping(uint256 => uint256) public rewardPerWeeks;

    address constant DeriAddress = 0xA487bF43cF3b10dffc97A9A744cbB7036965d3b9;
    address constant ArbitrumGatewayRouter =
        0x72Ce9c846789fdB6fC1f34aC4AD25Dd9ef7031ef;
    address constant ArbitrumGateway =
        0xa3A7B6F88361F48403514059F1F16C8E78d60EeC;
    address constant ZksyncL1Bridge =
        0x57891966931Eb4Bb6FB81430E6cE0A03AAbDe063;
    address constant WormholeEthereum =
        0x6874640cC849153Cb3402D193C33c416972159Ce;
    address constant WormholeBNB = 0x15a5969060228031266c64274a54e02Fbd924AbF;

    function approveGateway() public {
        IERC20(DeriAddress).approve(ArbitrumGateway, type(uint256).max);
    }

    function approveGatewayRouter() public {
        IERC20(DeriAddress).approve(ArbitrumGatewayRouter, type(uint256).max);
    }

    function approveZkBridge() public {
        IERC20(DeriAddress).approve(ZksyncL1Bridge, type(uint256).max);
    }

    function approveWormholeEthereum() public {
        IERC20(DeriAddress).approve(WormholeEthereum, type(uint256).max);
    }

    function approveAll() external {
        approveGateway();
        approveZkBridge();
        approveWormholeEthereum();
    }

    function callZksyncL2TransactionBaseCost(
        address contractAddress,
        uint256 _gasPrice,
        uint256 _gasLimit,
        uint256 _l2GasPerPubdataByteLimit
    ) public view returns (uint256) {
        bytes memory data = abi.encodeWithSelector(
            bytes4(
                keccak256(
                    bytes("l2TransactionBaseCost(uint256,uint256,uint256)")
                )
            ),
            _gasPrice,
            _gasLimit,
            _l2GasPerPubdataByteLimit
        );
        (bool success, bytes memory returnData) = contractAddress.staticcall(
            data
        );
        require(success, "The static call was not successful.");
        uint256 returnValue = abi.decode(returnData, (uint256));
        return returnValue;
    }

    function withdraw(address token) external _onlyAdmin_ {
        uint256 amount = IERC20(token).balanceOf(address(this));
        IERC20(token).transfer(msg.sender, amount);
    }

    function setRewardPerWeek(
        uint256 poolId,
        uint256 _rewardPerWeek
    ) external _onlyAdmin_ {
        rewardPerWeeks[poolId] = _rewardPerWeek;
    }

    function setRewardPerWeek(
        uint256[] calldata _rewardPerWeek
    ) external _onlyAdmin_ {
        for (uint256 i = 0; i < _rewardPerWeek.length; i++) {
            rewardPerWeeks[i] = _rewardPerWeek[i];
        }
    }

    function bridgeAll(CrossChainDetails[] calldata details) public payable {
        // Bridge to each cross chain address
        for (uint256 i = 0; i < details.length; i++) {
            if (details[i].isArbitrum) {
                IArbitrumTokenGateway(ArbitrumGatewayRouter).outboundTransfer{
                    value: details[i]._value
                }(
                    details[i]._token,
                    details[i]._to,
                    rewardPerWeeks[details[i].poolId],
                    details[i]._maxGas,
                    details[i]._gasPriceBid,
                    details[i]._data
                );
            } else {
                IZksyncL1ERC20Bridge(ZksyncL1Bridge).deposit{
                    value: details[i]._value
                }(
                    details[i]._l2Receiver,
                    details[i]._l1Token,
                    rewardPerWeeks[details[i].poolId],
                    details[i]._l2TxGasLimit,
                    details[i]._l2TxGasPerPubdataByte,
                    details[i]._refundRecipient
                );
            }
        }
        // Bridge to BNB
        if (rewardPerWeeks[3] > 0) {
            IWormhole(WormholeEthereum).freeze(
                rewardPerWeeks[3],
                56,
                WormholeBNB
            );
        }
    }

    function mintAndBridgeAll(
        Signature calldata signature,
        CrossChainDetails[] calldata details
    ) external payable {
        // Calculate the total amount for all transfers
        uint256 totalAmount = rewardPerWeeks[3];
        for (uint256 i = 0; i < details.length; i++) {
            totalAmount += rewardPerWeeks[details[i].poolId];
        }
        require(
            totalAmount == signature.amount,
            "DeriTokenManager: invalid total mint amount"
        );
        // Mint the tokens first
        IERC20(DeriAddress).mint(
            address(this),
            totalAmount,
            signature.deadline,
            signature.v,
            signature.r,
            signature.s
        );
        // IERC20(DeriAddress).mint(address(this), totalAmount);
        // Bridge to each cross chain address
        this.bridgeAll{value: msg.value}(details);
    }
}