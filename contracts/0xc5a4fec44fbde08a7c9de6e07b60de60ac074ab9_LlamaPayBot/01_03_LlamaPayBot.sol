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
}

interface LlamaPayFactory {
    function getLlamaPayContractByToken(address _token)
        external
        view
        returns (address predictedAddress, bool isDeployed);
}

contract LlamaPayBot {
    using SafeTransferLib for ERC20;

    address public immutable factory;
    address public bot;
    address public llama;
    address public newLlama = address(0);
    uint256 public fee = 50000; // Covers bot gas cost for calling function

    event WithdrawScheduled(
        address owner,
        address token,
        address from,
        address to,
        uint216 amountPerSec,
        uint40 starts,
        uint40 frequency,
        bytes32 id
    );

    event WithdrawCancelled(
        address owner,
        address token,
        address from,
        address to,
        uint216 amountPerSec,
        uint40 starts,
        uint40 frequency,
        bytes32 id
    );

    event WithdrawExecuted(
        address owner,
        address token,
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

    constructor(
        address _factory,
        address _bot,
        address _llama
    ) {
        factory = _factory;
        bot = _bot;
        llama = _llama;
    }

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
        address _token,
        address _from,
        address _to,
        uint216 _amountPerSec,
        uint40 _starts,
        uint40 _frequency
    ) external returns (bytes32 id) {
        id = calcWithdrawId(
            _token,
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
            _token,
            _from,
            _to,
            _amountPerSec,
            _starts,
            _frequency,
            id
        );
    }

    function cancelWithdraw(
        address _token,
        address _from,
        address _to,
        uint216 _amountPerSec,
        uint40 _starts,
        uint40 _frequency
    ) external returns (bytes32 id) {
        id = calcWithdrawId(
            _token,
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
            _token,
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
        address _token,
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
            (address llamapay, bool isDeployed) = LlamaPayFactory(factory)
                .getLlamaPayContractByToken(_token);
            require(isDeployed, "invalid llamapay contract");
            if (redirects[_to] != address(0)) {
                (uint256 withdrawableAmount, , ) = LlamaPay(llamapay)
                    .withdrawable(_from, _to, _amountPerSec);
                LlamaPay(llamapay).withdraw(_from, _to, _amountPerSec);
                ERC20(_token).safeTransferFrom(
                    _to,
                    redirects[_to],
                    withdrawableAmount
                );
            } else {
                LlamaPay(llamapay).withdraw(_from, _to, _amountPerSec);
            }
        }
        if (_emitEvent) {
            emit WithdrawExecuted(
                _owner,
                _token,
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
        address _token,
        address _from,
        address _to,
        uint216 _amountPerSec,
        uint40 _starts,
        uint40 _frequency
    ) public pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    _token,
                    _from,
                    _to,
                    _amountPerSec,
                    _starts,
                    _frequency
                )
            );
    }
}