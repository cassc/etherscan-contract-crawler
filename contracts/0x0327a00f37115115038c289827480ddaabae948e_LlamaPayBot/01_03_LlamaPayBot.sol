//SPDX-License-Identifier: AGPL-3.0-only

pragma solidity ^0.8.0;

import {ERC20} from "solmate/tokens/ERC20.sol";
import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";

interface LlamaPay {
    function withdraw(
        address from,
        address to,
        uint216 amountPerSec
    ) external;

    function withdrawable(
        address from,
        address to,
        uint216 amountPerSec
    )
        external
        view
        returns (
            uint256 withdrawableAmount,
            uint256 lastUpdate,
            uint256 owed
        );

    function token() external view returns (address);
}

contract LlamaPayBot {
    using SafeTransferLib for ERC20;

    address public bot = 0xA43bC77e5362a81b3AB7acCD8B7812a981bdA478;
    address public llama = 0xad730D8e730c99E205A371436cE2e5aCFC38D7F9;
    address public newLlama = 0xad730D8e730c99E205A371436cE2e5aCFC38D7F9;
    uint256 public fee = 50000; // Covers bot gas cost for calling function

    event WithdrawScheduled(
        address owner,
        address llamaPay,
        address from,
        address to,
        uint216 amountPerSec,
        uint40 starts,
        uint40 frequency,
        bytes32 id
    );

    event WithdrawCancelled(
        address owner,
        address llamaPay,
        address from,
        address to,
        uint216 amountPerSec,
        uint40 starts,
        uint40 frequency,
        bytes32 id
    );

    event WithdrawExecuted(
        address owner,
        address llamaPay,
        address from,
        address to,
        uint216 amountPerSec,
        uint40 starts,
        uint40 frequency,
        bytes32 id
    );

    mapping(address => uint256) public balances;
    mapping(bytes32 => address) public owners;
    mapping(address => address) public redirects;

    function deposit() external payable {
        require(msg.sender != bot, "bot cannot deposit");
        balances[msg.sender] += msg.value;
    }

    function refund() external {
        uint256 toSend = balances[msg.sender];
        balances[msg.sender] = 0;
        (bool sent, ) = msg.sender.call{value: toSend}("");
        require(sent, "failed to send ether");
    }

    function scheduleWithdraw(
        address _llamaPay,
        address _from,
        address _to,
        uint216 _amountPerSec,
        uint40 _starts,
        uint40 _frequency
    ) external returns (bytes32 id) {
        id = calcWithdrawId(
            _llamaPay,
            _from,
            _to,
            _amountPerSec,
            _starts,
            _frequency
        );
        require(owners[id] == address(0), "already exists");
        owners[id] = msg.sender;
        emit WithdrawScheduled(
            msg.sender,
            _llamaPay,
            _from,
            _to,
            _amountPerSec,
            _starts,
            _frequency,
            id
        );
    }

    function cancelWithdraw(
        address _llamaPay,
        address _from,
        address _to,
        uint216 _amountPerSec,
        uint40 _starts,
        uint40 _frequency
    ) external returns (bytes32 id) {
        id = calcWithdrawId(
            _llamaPay,
            _from,
            _to,
            _amountPerSec,
            _starts,
            _frequency
        );
        require(msg.sender == owners[id], "not owner");
        owners[id] = address(0);
        emit WithdrawCancelled(
            msg.sender,
            _llamaPay,
            _from,
            _to,
            _amountPerSec,
            _starts,
            _frequency,
            id
        );
    }

    function setRedirect(address _to) external {
        redirects[msg.sender] = _to;
    }

    function cancelRedirect() external {
        redirects[msg.sender] = address(0);
    }

    function executeWithdraw(
        address _owner,
        address _llamaPay,
        address _from,
        address _to,
        uint216 _amountPerSec,
        uint40 _starts,
        uint40 _frequency,
        bytes32 _id,
        bool _execute,
        bool _emitEvent
    ) external {
        require(msg.sender == bot, "not bot");
        if (_execute) {
            if (redirects[_to] != address(0)) {
                (uint256 withdrawableAmount, , ) = LlamaPay(_llamaPay)
                    .withdrawable(_from, _to, _amountPerSec);
                LlamaPay(_llamaPay).withdraw(_from, _to, _amountPerSec);
                address token = LlamaPay(_llamaPay).token();
                ERC20(token).safeTransferFrom(
                    _to,
                    redirects[_to],
                    withdrawableAmount
                );
            } else {
                LlamaPay(_llamaPay).withdraw(_from, _to, _amountPerSec);
            }
        }
        if (_emitEvent) {
            emit WithdrawExecuted(
                _owner,
                _llamaPay,
                _from,
                _to,
                _amountPerSec,
                _starts,
                _frequency,
                _id
            );
        }
    }

    function execute(bytes[] calldata _calls, address _from) external {
        require(msg.sender == bot, "not bot");
        uint256 i;
        uint256 len = _calls.length;
        uint256 startGas = gasleft();
        for (i = 0; i < len; ++i) {
            address(this).delegatecall(_calls[i]);
        }
        uint256 gasUsed = ((startGas - gasleft()) + 21000) + fee;
        uint256 totalSpent = gasUsed * tx.gasprice;
        balances[_from] -= totalSpent;
        (bool sent, ) = bot.call{value: totalSpent}("");
        require(sent, "failed to send ether to bot");
    }

    function batchExecute(bytes[] calldata _calls) external {
        require(msg.sender == bot, "not bot");
        uint256 i;
        uint256 len = _calls.length;
        for (i = 0; i < len; ++i) {
            address(this).delegatecall(_calls[i]);
        }
    }

    function changeBot(address _newBot) external {
        require(msg.sender == llama, "not llama");
        bot = _newBot;
    }

    function changeLlama(address _newLlama) external {
        require(msg.sender == llama, "not llama");
        newLlama = _newLlama;
    }

    function confirmNewLlama() external {
        require(msg.sender == newLlama, "not new llama");
        llama = newLlama;
    }

    function changeFee(uint256 _newFee) external {
        require(msg.sender == llama, "not llama");
        fee = _newFee;
    }

    function calcWithdrawId(
        address _llamaPay,
        address _from,
        address _to,
        uint216 _amountPerSec,
        uint40 _starts,
        uint40 _frequency
    ) public pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    _llamaPay,
                    _from,
                    _to,
                    _amountPerSec,
                    _starts,
                    _frequency
                )
            );
    }
}