// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

import "./libs/interfaces.sol";
import "stl-contracts/tokens/extensions/Minter.sol";

contract RoyaltyReceiverMinterCollect is OwnableUpgradeable, UUPSUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    using ECDSA for bytes32;

    address _bex;

    uint256 constant _MAX_AMOUNT = (1 << 254) - 1;
    uint256 constant _HOLDER_BIT = 1 << 255;
    uint256 constant _MINTER_BIT = 1 << 254;
    uint256 constant _15_BIT = (1 << 15) - 1;

    struct ERC20Payment {
        // solhint-disable-next-line var-name-mixedcase
        bytes32 TX;
        uint256 amount;
        address erc20;
        uint256 tokenId;
    }

    struct ETHPayment {
        // solhint-disable-next-line var-name-mixedcase
        bytes32 TX;
        uint256 amount;
        uint256 tokenId;
    }

    struct ERC20toPay {
        address erc20;
        uint256 beneficiaryAmount;
        uint256 userAmount;
    }

    struct MinterAndParent {
        address minter;
        address parent;
    }

    // if value set then TX already parsed and minter and contract amounts increased
    // we use _holderAmounts for both ETH and ERC20, TX must be unique
    // we use 2 higher bits of value to mark that TX was withdrawn by:
    // Holder(hihger bit 1<<255) and Minter(higher bit-1 = 1<<254)
    mapping(bytes32 => uint256) private _holderAmounts;

    address private _tokenDetector;

    // its some address, who can share ERC20 royalties for OG owners
    address public beneficiary;

    // 100% = 10000. percent of amount for minter+contract+holder
    // each value use 16 bits
    // 16 lower bits -> holder percentage
    // next 16 lower bits -> holder percentage
    // 2 values: 50% contract + 50% minter
    uint256 public minterAndContractPercentages;

    // !!! unused variable. stay it to safe upgrade
    address[] _supportedContracts;
    // contract => amount
    // !!! unused variable. stay it to safe upgrade
    mapping(address => uint256) private _contractsBalances;

    uint256 public contractsBalance;

    // if its true then collect all contracts funds under single variable and withdraw it to "beneficeary"
    // !!! unused variable. stay it to safe upgrade
    bool public collectContracts;

    // erc20 => amount
    // slither-disable-next-line naming-convention
    mapping(address => uint256) private _ERC20beneficearyBalances; // solhint-disable-line var-name-mixedcase

    mapping(address => uint256) _minterBalances;

    // slither-disable-next-line naming-convention
    mapping(address => mapping(address => uint256)) _ERC20minterBalances; // solhint-disable-line var-name-mixedcase

    // need to redeploy logic contract to change value
    bool constant autoWithdrawContractFunds = false;

    event RoyaltyPaid(bytes32 indexed tx, address indexed receiver, uint256 sum);
    event MinterCollectedRoyaltyPaid(address indexed receiver, uint256 sum);
    event RoyaltyPaidERC20(bytes32 indexed tx, address indexed erc20, address indexed receiver, uint256 sum);

    event TokenDetectorSet(address indexed previousAddress, address indexed newAddress);

    event ReceiversDataSet(address indexed addr, uint256 percent);

    // solhint-disable-next-line var-name-mixedcase, func-param-name-mixedcase
    event ERC20ReceiverSet(address indexed ERC20Receiver);

    function initialize(address initialTokenDetector, address beneficeary_) public initializer {
        require(initialTokenDetector != address(0), "Address required");
        __Ownable_init();
        __UUPSUpgradeable_init();
        _tokenDetector = initialTokenDetector;
        // minter - 40%
        // holder - 20%
        // contract: rest (40%)
        minterAndContractPercentages = ((40 * 100) << 16) + 20 * 100;
        _setERC20Receiver(beneficeary_);
    }

    // use for tests
    function setBex(address newBex) external onlyOwner {
        require(newBex != address(0), "Address required");
        _bex = newBex;
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}

    function _getBexAddress() internal view returns (address) {
        return _bex;
    }

    /**
    Revert if TX unknown
    */
    function getTxState(
        bytes32 _tx
    ) external view returns (bool holderWithdrawn, bool minterWithdrawn, uint256 amount) {
        amount = _holderAmounts[_tx];
        require(amount > 0, "TX not exists");
        holderWithdrawn = _isPaidToHolder(amount);
        minterWithdrawn = _isPaidToMinter(amount);
        amount = amount & _MAX_AMOUNT;
    }

    // slither-disable-start similar-names
    // slither-disable-start uninitialized-local
    // function _fillTXData(ETHPayment[] memory _ethPaymetsData, bool onlyNewTxes) internal {
    function _fillTXData(ETHPayment[] memory _ethPaymetsData) internal {
        uint256 lastContractSum = contractsBalance;

        uint percentages = minterAndContractPercentages;

        bool parsedAtLeastSingleTx = false;

        for (uint256 i = 0; i < _ethPaymetsData.length; i++) {
            ETHPayment memory txData = _ethPaymetsData[i];

            require(txData.amount <= _MAX_AMOUNT, "Max amount allowed is uint254 - 1");

            uint256 bitsAndAmount = _holderAmounts[txData.TX];

            if (bitsAndAmount > 0) {
                // TX already parsed, skip..
                continue;
            }

            parsedAtLeastSingleTx = true;

            (uint256 contractPart, , ) = _getRoyaltyValues(
                txData.amount,
                percentages
            );

            lastContractSum += contractPart;

            _holderAmounts[txData.TX] = txData.amount;
        }

        // save last value
        if (parsedAtLeastSingleTx) {
            contractsBalance = lastContractSum;
        }
    }

    // slither-disable-end uninitialized-local

    function _fillERC20TXData(ERC20Payment[] memory _erc20paymetsData) internal {

        uint256 lastBeneficearySum = 0;
        address lastErc20 = address(0);
        bool parsedAtLeastSingleTx = false;
        uint percentages = minterAndContractPercentages;

        for (uint256 i = 0; i < _erc20paymetsData.length; i++) {
            ERC20Payment memory txData = _erc20paymetsData[i];

            require(txData.amount <= _MAX_AMOUNT, "Max amount allowed is uint254 - 1");

            // if TX already exists then return amount to withdraw and clear
            // saved amount for current user in the _holderAmounts list
            uint256 bitsAndAmount = _holderAmounts[txData.TX];

            if (bitsAndAmount > 0) {
                // TX already parsed, skip..
                continue;
            }

            parsedAtLeastSingleTx = true;

            (uint256 contractPart, , ) = _getRoyaltyValues(
                txData.amount,
                percentages
            );

            if (i == 0) {
                lastBeneficearySum = _ERC20beneficearyBalances[txData.erc20] + contractPart;
            } else {
                if (txData.erc20 != lastErc20) {
                    _ERC20beneficearyBalances[lastErc20] = lastBeneficearySum;
                    lastBeneficearySum = _ERC20beneficearyBalances[txData.erc20] + contractPart;
                } else {
                    lastBeneficearySum += contractPart;
                }
            }

            _holderAmounts[txData.TX] = txData.amount;

            lastErc20 = txData.erc20;
        }

        // save last values
        if (parsedAtLeastSingleTx) {
            _ERC20beneficearyBalances[lastErc20] = lastBeneficearySum;
        }
    }

    // slither-disable-end similar-names

    // validate signature and parse input data
    function _convertValidateERC20Input(
        bytes calldata payload,
        bytes memory signature
    )
        internal
        view
        returns (
            // address receiver,
            ERC20Payment[] memory _erc20paymetsData
        )
    {
        _validateSignature(payload, signature);
        _erc20paymetsData = abi.decode(payload, (ERC20Payment[]));
    }

    // validate signature and parse input data
    function _convertValidateETHInput(
        bytes calldata payload,
        bytes memory signature
    ) internal view returns (ETHPayment[] memory _ethPaymetsData) {
        _validateSignature(payload, signature);
        _ethPaymetsData = abi.decode(payload, (ETHPayment[]));
    }

    // slither-disable-start calls-loop
    function _validateHolder(uint256 tokenId) internal view {
        iMinterAndParent erc721minter = iMinterAndParent(_getBexAddress());

        address holder = erc721minter.getParentNftHolder(tokenId);

        require(_msgSender() == holder, "Requestor not allowed");
    }

    // slither-disable-end calls-loop

    /**
    Minter use simplified flow, no need to check Parent NFT holder address
    Minter pays gas to send royalty to Parent Contract, 
    because Contract itself cant request withdraw
    */

    function withdrawETHasMinter(bytes calldata payload, bytes memory signature) public {
        ETHPayment[] memory _ethPaymetsData = _convertValidateETHInput(payload, signature);

        // only new TXes allowed, other TXes already collected, no need to waste gas
        _fillTXData(_ethPaymetsData);

        address minter = address(0);

        uint lastTokenID = 0;

        uint percentages = minterAndContractPercentages;

        uint256 minterAmount = 0;

        for (uint256 i = 0; i < _ethPaymetsData.length; i++) {
            ETHPayment memory txData = _ethPaymetsData[i];

            bytes32 txId = txData.TX;
            uint tokenId = txData.tokenId;
            uint256 bitsAndAmount = _holderAmounts[txId];

            // high bit means that Holder royalty for current TX already paid
            require(!_isPaidToMinter(bitsAndAmount), "TX already withdrawn");

            (, uint256 minterPart, ) = _getRoyaltyValues(
                txData.amount,
                percentages
            );

            require (txData.amount == _clearPaidBits(bitsAndAmount), "TX amounts dont fit");

            // slither-disable-start variable-scope
            // slither-disable-start calls-loop
            if (i == 0 || lastTokenID != tokenId) {
                minter = Minter(_bex).getMinter(tokenId);
                require(minter == _msgSender(), "Not a NFT minter");                    
            }

            lastTokenID = tokenId;
            minterAmount += minterPart;
            
            // slither-disable-end calls-loop
            // slither-disable-end variable-scope

            emit RoyaltyPaid(txId, _msgSender(), minterPart);

            // set as paid to Minter
            _holderAmounts[txId] = _markAsPaidToMinter(bitsAndAmount);

        }

        _pay(minterAmount, _msgSender());
        // if minter has some balance then Parent Contract Owners has some funds to withdraw
        _payContractsRoyalties();

    }

    /**
    withdraw multiple ERC20 payments with single TX. payload should be signed by SERVICE 
    and user/nifty/stl can run transaction. It will send funds to the requestor and save 
    other parties data to the storage.

    In the input should be full royalty values. to save GAS send data, sorted by 
    ERC20 contract TXes will be saved to avoid double spending
    */
    function withdrawERC20asMinter(bytes calldata payload, bytes memory signature) public {
        ERC20Payment[] memory _erc20paymetsData = _convertValidateERC20Input(payload, signature);

        uint256 _collectedAmount = 0;

        // slither-disable-next-line uninitialized-local
        ERC20Payment memory txData;
        // slither-disable-next-line uninitialized-local
        ERC20Payment memory lastTxData;

        uint percentages = minterAndContractPercentages;
        uint256 bitsAndAmount = 0;

        _fillERC20TXData(_erc20paymetsData);

        for (uint256 i = 0; i < _erc20paymetsData.length; i++) {
            txData = _erc20paymetsData[i];

            // uint256 minterAmount = _ERC20minterBalances[erc20][_msgSender()];
            bitsAndAmount = _holderAmounts[txData.TX];

            uint amountWithoutBits = _clearPaidBits(bitsAndAmount);
            require (txData.amount == amountWithoutBits, "TX amounts dont fit");

            (, uint256 minterPart, ) = _getRoyaltyValues(
                txData.amount,
                percentages
            );


            // high bit means that Holder royalty for current TX already paid
            require(!_isPaidToMinter(bitsAndAmount), "TX already withdrawn");
            // set as paid to Holder
            _holderAmounts[txData.TX] = _markAsPaidToMinter(bitsAndAmount);
            // no need to validate same tokenId again
            if (i == 0 || txData.tokenId != lastTxData.tokenId){
                address _minter = Minter(_bex).getMinter(txData.tokenId);
                require(_minter == _msgSender(), "Not a NFT minter");
            }



            emit RoyaltyPaidERC20(txData.TX, txData.erc20, _msgSender(), minterPart);

            if (i > 0 && txData.erc20 != lastTxData.erc20) {
                _sendERC20(lastTxData.erc20, _collectedAmount, _msgSender(), lastTxData.TX);
                _collectedAmount = minterPart;
            } else {
                _collectedAmount += minterPart;
            }

            lastTxData = txData;

        }
        _sendERC20(lastTxData.erc20, _collectedAmount, _msgSender(), lastTxData.TX);
    }

    function withdrawErc20ContractOwner(bytes32 tx_, address erc20) public {
        uint256 beneficiaryAmount = _ERC20beneficearyBalances[erc20];
        if (beneficiaryAmount > 0) {
            _ERC20beneficearyBalances[erc20] = 0;
            emit RoyaltyPaidERC20(tx_, erc20, beneficiary, beneficiaryAmount);
            _payERC20(erc20, beneficiaryAmount, beneficiary);
        }
    }

    // slither-disable-start reentrancy-eth
    function _payContractsRoyalties() internal {
        uint256 amount = contractsBalance;

        if (amount > 0) {
            delete contractsBalance;
            _pay(amount, beneficiary);
        }
    }

    // slither-disable-end reentrancy-eth

    function withdrawEthAsHolder(bytes calldata payload, bytes memory signature) public {
        ETHPayment[] memory _ethPaymetsData = _convertValidateETHInput(payload, signature);

        uint256 _collectedAmount;

        ETHPayment memory txData;
        uint lastTokenId = 0;
        uint percentages = minterAndContractPercentages;

        // require to add all TXes, because in next loop they will be collected
        _fillTXData(_ethPaymetsData);

        for (uint256 i = 0; i < _ethPaymetsData.length; i++) {
            txData = _ethPaymetsData[i];

            bytes32 txId = txData.TX;
            uint256 bitsAndAmount = _holderAmounts[txId];
            // high bit means that Holder royalty for current TX already paid
            require(!_isPaidToHolder(bitsAndAmount), "TX already withdrawn");
            _holderAmounts[txId] = _markAsPaidToHolder(bitsAndAmount);

            uint amountWithoutBits = _clearPaidBits(bitsAndAmount);
            require (txData.amount == amountWithoutBits, "TX amounts dont fit");

            (, , uint256 holderPart) = _getRoyaltyValues(
                txData.amount,
                percentages
            );

            emit RoyaltyPaid(_ethPaymetsData[i].TX, _msgSender(), holderPart);
            
            if (i == 0 || txData.tokenId != lastTokenId){
                _validateHolder(txData.tokenId);
            }

            _collectedAmount += holderPart;
            
            lastTokenId = txData.tokenId;
            
        }

        _pay(_collectedAmount, _msgSender());
    }

    function withdrawERC20AsHolder(bytes calldata payload, bytes memory signature) public {
        ERC20Payment[] memory _erc20paymetsData = _convertValidateERC20Input(payload, signature);

        uint256 _collectedAmount = 0;

        // slither-disable-next-line uninitialized-local
        ERC20Payment memory txData;
        // slither-disable-next-line uninitialized-local
        ERC20Payment memory lastTxData;

        uint percentages = minterAndContractPercentages;
        uint256 bitsAndAmount = 0;

        // require to add all TXes, because in next loop they will be collected
        _fillERC20TXData(_erc20paymetsData);

        for (uint256 i = 0; i < _erc20paymetsData.length; i++) {
            txData = _erc20paymetsData[i];

            bitsAndAmount = _holderAmounts[txData.TX];

            // high bit means that Holder royalty for current TX already paid
            require(!_isPaidToHolder(bitsAndAmount), "TX already withdrawn");
            _holderAmounts[txData.TX] = _markAsPaidToHolder(bitsAndAmount);

            uint amountWithoutBits = _clearPaidBits(bitsAndAmount);
            require (txData.amount == amountWithoutBits, "TX amounts dont fit");

            (, , uint256 holderPart) = _getRoyaltyValues(
                txData.amount,
                percentages
            );

            emit RoyaltyPaidERC20(txData.TX, txData.erc20, _msgSender(), holderPart);

            // no need to validate same tokenId again
            if (i == 0 || txData.tokenId != lastTxData.tokenId){
                _validateHolder(txData.tokenId);
            }

            if (i > 0 && txData.erc20 != lastTxData.erc20) {
                _sendERC20(lastTxData.erc20, _collectedAmount, _msgSender(), lastTxData.TX);
                _collectedAmount = holderPart;
            } else {
                _collectedAmount += holderPart;
            }

            lastTxData = txData;
        }

        _sendERC20(lastTxData.erc20, _collectedAmount, _msgSender(), lastTxData.TX);
    }

    function _isPaidToHolder(uint256 amount) internal pure returns (bool) {
        return (amount & _HOLDER_BIT) > 0;
    }

    function _isPaidToMinter(uint256 amount) internal pure returns (bool) {
        return (amount & _MINTER_BIT) > 0;
    }

    function _markAsPaidToHolder(uint256 amount) internal pure returns (uint256) {
        return amount | _HOLDER_BIT;
    }

    function _markAsPaidToMinter(uint256 amount) internal pure returns (uint256) {
        return amount | _MINTER_BIT;
    }

    function _clearPaidBits(uint256 amount) internal pure returns (uint256) {
        return amount & (_MINTER_BIT - 1);
    }

    /*
    Its just a combine of ERC20 withdraw and ETH withdraw
    */
    function combinedWithdrawMinter(
        bytes calldata erc20payload,
        bytes memory erc20signature,
        bytes calldata payload,
        bytes memory signature
    ) public {
        if (erc20payload.length > 0 && erc20signature.length > 0) {
            withdrawERC20asMinter(erc20payload, erc20signature);
        } 
        if (payload.length > 0 && signature.length > 0) {
            withdrawETHasMinter(payload, signature);
        } else if(erc20payload.length == 0 || erc20signature.length == 0 ) {
            revert("Input data required");
        }
    }

    function combinedWithdrawHolder(
        bytes calldata erc20payload,
        bytes memory erc20signature,
        bytes calldata payload,
        bytes memory signature
    ) public {
        if (erc20payload.length > 0 && erc20signature.length > 0) {
            withdrawERC20AsHolder(erc20payload, erc20signature);
        } 
        if (payload.length > 0 && signature.length > 0) {
            withdrawEthAsHolder(payload, signature);
        } else if(erc20payload.length == 0 || erc20signature.length == 0) {
            revert("Input data required");
        }
    }

    function combinedWithdraw(
        bytes calldata erc20payloadMinter,
        bytes memory erc20signatureMinter,
        bytes calldata payloadMinter,
        bytes memory signatureMinter,
        bytes calldata erc20payloadHolder,
        bytes memory erc20signatureHolder,
        bytes calldata payloadHolder,
        bytes memory signatureHolder
    ) external {
        if (erc20payloadMinter.length > 0 || payloadMinter.length > 0) {
            combinedWithdrawMinter(erc20payloadMinter, erc20signatureMinter, payloadMinter, signatureMinter);
            }
        if (erc20payloadHolder.length > 0 || payloadHolder.length > 0) {
            combinedWithdrawHolder(erc20payloadHolder, erc20signatureHolder, payloadHolder, signatureHolder);
        } 
        if (
            erc20payloadMinter.length == 0 
            && payloadMinter.length == 0
            && erc20payloadHolder.length == 0
            && payloadHolder.length == 0
            ) {
            revert("Input data required");
        }
    }

    function _sendERC20(address erc20, uint256 amount, address receiver, bytes32 tx_) internal {
        _payERC20(erc20, amount, receiver);

        // if minter has some balance then Parent Contract Owners has some funds to withdraw
        if (autoWithdrawContractFunds) {
            withdrawErc20ContractOwner(tx_, erc20);
        }
    }

    function _payERC20(address erc20, uint256 amount, address receiver) internal {
        IERC20Upgradeable erc20c = IERC20Upgradeable(erc20);
        // validation disabled to save 3k gas
        // get this contract balabce to avoid overflow
        // uint balance = erc20c.balanceOf(address(this));
        require(amount > 0, "Nothing to pay here");

        // emit RoyaltyPaidERC20(tx_, erc20, receiver, amount);

        erc20c.safeTransfer(receiver, amount);
    }

    function _getRoyaltyValues(
        uint256 amount,
        uint percentages
    ) internal pure returns (uint256 _contract, uint256 _minter, uint256 _holder) {
        uint256 holderPercent = percentages & _15_BIT;
        uint256 minterPercent = (percentages >> 16) & _15_BIT;

        require((holderPercent + minterPercent) < 10001, "Wrong percentages");

        _holder = (amount * holderPercent) / 10000;
        _minter = (amount * minterPercent) / 10000;
        _contract = amount - _minter - _holder;
    }

    receive() external payable {}

    // slither-disable-start low-level-calls
    function _pay(uint256 amount, address receiver) internal {
        // slither-disable-next-line arbitrary-send-eth
        (bool sent, ) = receiver.call{value: amount}("");
        require(sent, "Failed to send Ether");
    }

    // slither-disable-end low-level-calls

    function _validateSignature(bytes calldata payload, bytes memory signature) internal view {
        address signerAddress = keccak256(payload).toEthSignedMessageHash().recover(signature);

        require(signerAddress == _tokenDetector, "Payload must be signed");
    }

    function setTokenDetector(address addr) external onlyOwner {
        require(addr != address(0), "Address required");
        _setTokenDetector(addr);
    }

    function _setTokenDetector(address addr) internal {
        require(addr != address(0), "Address required");
        emit TokenDetectorSet(_tokenDetector, addr);
        _tokenDetector = addr;
    }

    function setERC20Receiver(address addr) external onlyOwner {
        _setERC20Receiver(addr);
    }

    function _setERC20Receiver(address addr) internal {
        require(addr != address(0), "Address required");
        beneficiary = addr;

        emit ERC20ReceiverSet(addr);
    }

    function getMinterCollectedBalance(address minter) public view returns (uint256) {
        return _minterBalances[minter];
    }

    function getERC20MinterCollectedBalance(address erc20, address minter) external view returns (uint256) {
        return _ERC20minterBalances[erc20][minter];
    }
}