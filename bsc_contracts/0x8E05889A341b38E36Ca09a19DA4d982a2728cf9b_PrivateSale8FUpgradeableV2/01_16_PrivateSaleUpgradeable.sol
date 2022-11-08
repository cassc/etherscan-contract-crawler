// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0;
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./NFTUpgradeable.sol";

abstract contract ERC20Interface {
    function balanceOf(address whom) view virtual public returns (uint);
    function transfer(address to, uint256 amount) public virtual returns (bool);
}

contract PrivateSale8FUpgradeableV2 is Initializable, OwnableUpgradeable {
    address public usdContractAddress;
    address public tokenAddress;
    address public nftContractAddress;

    uint public tokenPrice;
    uint tokenDebt;
    uint public vestingTime;

    struct Payment {
        uint amount;
        uint timestamp;
        uint price;
        uint tokensAmount;
        uint withdrawed;
        uint opened;
        bool inStake;
        uint256 nftTokenId;
    }

    uint multiplier;

    struct Balance {
        Payment payment;
    }

    mapping(uint256 => Balance) public balances;

    uint public vestingStartTime;

    uint public burnTransferFee;
    uint constant feeMuplipier = 100000000;
    uint tgePercent;
    uint256 public defaultImageMaximumAmount;

    function setBurnTransferFee(uint feePercent) public onlyOwner {
        require (feePercent < 10000000000, "Percent must be less 100");
        burnTransferFee = feePercent / 100;
    }

    modifier vestingStarted {
        require(vestingStartTime > 0, "Vesting must be started");
        _;
    }

    modifier onlyTokenOwner(uint256 tokenId) {
        address ownerOfToken = PrivateSaleNft8FContractV1(nftContractAddress).fullOwnerOf(tokenId);
        require(ownerOfToken == tx.origin, "Only owner of token can do this");
        _;
    }

    uint256 decimalsMultiplier;
    uint public cliffTime;
    address public stakeContractAddress;
    uint256 public minAmountForEntry;
    uint public maxCountBaseNft;
    uint public currentDefaultNft;
    uint public currentExpensiveNft;
    function initialize(
        address _tokenAddress,
        address _usdContractAddress,
        address _nftContractAddress,
        uint _tgePercent,
        uint256 _defaultImageMaximumAmount,
        uint _maxCountBaseNft
    ) external initializer {
        require (_tgePercent < 10000000000, "TGE Percent must be less 100");
        __Ownable_init();
        decimalsMultiplier = 10 ** 18;
        tokenAddress = _tokenAddress;
        usdContractAddress = _usdContractAddress;
        nftContractAddress = _nftContractAddress;
        cliffTime = 90 days;
        tgePercent = _tgePercent / 100;
        defaultImageMaximumAmount = _defaultImageMaximumAmount;
        maxCountBaseNft = 800;
        currentDefaultNft = 0;
        currentExpensiveNft = 0;
        maxCountBaseNft = _maxCountBaseNft;
    }

    function setTokenAddress(address _tokenAddress) public onlyOwner {
        tokenAddress = _tokenAddress;
    }

    function setNftContract(address _nftContractAddress) public onlyOwner {
        nftContractAddress = _nftContractAddress;
    }

    function openToken(uint256 tokenId) public onlyTokenOwner(tokenId) {
        require(balances[tokenId].payment.opened == 0, "Token already opened");
        PrivateSaleNft8FContractV1(nftContractAddress).burnTokenAfterOpen(tokenId);
        balances[tokenId].payment.opened = block.timestamp;
    }

    function setCliffTime(uint _cliffTime) public onlyOwner {
        cliffTime = _cliffTime;
    }

    function transferDecrease(uint256 tokenId) public {
        require(msg.sender == nftContractAddress, "Only NFT contract can decrease");
        uint256 fee = balances[tokenId].payment.tokensAmount * burnTransferFee / feeMuplipier;
        balances[tokenId].payment.tokensAmount = balances[tokenId].payment.tokensAmount - fee;
    }

    function startVesting() public onlyOwner {
        vestingStartTime = block.timestamp;
    }

    function setPrice(uint _tokenPrice) public onlyOwner {
        tokenPrice = _tokenPrice;
    }

    function getTokenBalance(address addr) public view returns (uint byBalance) { //todo delete
        byBalance = ERC20Interface(tokenAddress).balanceOf(addr);
    }
    function changeVestingTime (uint time) public onlyOwner {
        vestingTime = time;
    }

    function stakeNft(uint256 tokenId) public onlyTokenOwner(tokenId) {
        require(!balances[tokenId].payment.inStake, "Nft already in stake");
        require(stakeContractAddress != address (0), "Address staking contract must be not empty");
        require(msg.sender == stakeContractAddress, "Only for staking contract");
        balances[tokenId].payment.inStake = true;
    }

    // Amount is transferred now. Later it will be native erc-20 transfer of usdt by approvance
    function buyToken(uint256 amount, bool openImmediate, address receiver) public {
        require(amount >= minAmountForEntry, 'Amount must be >= minimal amount for entry in Private Sale');
        (bool s,) = usdContractAddress.call(abi.encodeWithSelector(bytes4(keccak256(bytes('transferFrom(address,address,uint256)'))), msg.sender, address(this), amount));
        require(s, 'Transfer error');
        require(tokenPrice > 0, "Token price must be not zero");
        uint byBalance = ERC20Interface(tokenAddress).balanceOf(address(this));
        uint tokensAmount = decimalsMultiplier * amount / tokenPrice;
        require((tokenDebt + tokensAmount) < byBalance, "Not enough tokens on PS contract");
        if (receiver == address(0)) {
            receiver = address(tx.origin);
        }
        if (amount < defaultImageMaximumAmount) {
            require(currentDefaultNft <= maxCountBaseNft, 'Nft from category "based" reached maximum count');
        }
        uint nftTokenId = PrivateSaleNft8FContractV1(nftContractAddress).privateSaleMint(receiver, amount < defaultImageMaximumAmount);
        Payment memory newPayment = Payment(
            amount,
            block.timestamp,
            tokenPrice,
            tokensAmount,
            0,
            openImmediate ? block.timestamp : 0,
            false,
            nftTokenId
        );
        if (openImmediate) {
            PrivateSaleNft8FContractV1(nftContractAddress).burnTokenAfterOpen(nftTokenId);
        }
        balances[nftTokenId].payment = newPayment;
        tokenDebt+=tokensAmount;
    }

    function getPayment(uint256 tokenId) public view returns (Payment memory) {
        return balances[tokenId].payment;
    }

    function isOpened(uint256 tokenId) public view returns (bool) {
        Payment memory pay = this.getPayment(tokenId);
        return pay.nftTokenId == tokenId && pay.opened > 0;
    }

    function getTokenDebt () public view onlyOwner returns (uint)  {
        return tokenDebt;
    }

    function changeMultiplier (uint _multiplier) public onlyOwner {
        multiplier = _multiplier;
    }

    function getTgeInfo(uint256 fullTokensAmount) public view returns (uint256 tokensForTge, uint256 tokensAfterTge) {
        tokensForTge = fullTokensAmount * tgePercent / feeMuplipier;
        tokensAfterTge = fullTokensAmount - tokensForTge;
    }

    function calculateWithdrawAvailable(uint256 tokenId) public view vestingStarted onlyTokenOwner(tokenId) returns (uint256, uint256, uint256)  {
        uint256 amount;
        uint timeToCheck = vestingStartTime + cliffTime;
        uint256 fullTokensAmount = balances[tokenId].payment.tokensAmount;
        (uint256 tokensForTge, uint256 tokensAfterTge) = (getTgeInfo(fullTokensAmount));
        if (balances[tokenId].payment.opened > vestingStartTime) {
            timeToCheck = balances[tokenId].payment.opened + cliffTime;
        }
        if (block.timestamp < timeToCheck) {
            amount = tokensForTge;
        } else {
            if (block.timestamp - timeToCheck >= vestingTime) {
                amount = fullTokensAmount;
            } else {
                amount = (
                    (
                        decimalsMultiplier * (block.timestamp - timeToCheck)
                        /
                        vestingTime
                    )
                    * tokensAfterTge
                    / decimalsMultiplier
                    );
            }
        }
        amount -= balances[tokenId].payment.withdrawed;
        return (amount, block.timestamp, timeToCheck);
    }

    function claimMyMoney (uint256 tokenId, uint256 amountToWithdraw) public vestingStarted onlyTokenOwner(tokenId) {
        require(balances[tokenId].payment.opened > 0, "Token must be opened!");
        (uint256 amount,,) = calculateWithdrawAvailable(tokenId);
        if (amountToWithdraw != 0) {
            require(amountToWithdraw < amount, "amount is too high");
            amount = amountToWithdraw;
        }
        (bool status, ) = tokenAddress.call(abi.encodeWithSelector(bytes4(keccak256(bytes('transfer(address,uint256)'))), tx.origin, amount));
        tokenDebt -= amount;
        balances[tokenId].payment.withdrawed += amount;
        require (status, 'transfer error');
    }

    function withdrawUsdt(address to) public  {
        uint byBalance = ERC20Interface(usdContractAddress).balanceOf(address(this));
        (bool s,) = usdContractAddress.call(abi.encodeWithSelector(bytes4(keccak256(bytes('transfer(address,uint256)'))), to, byBalance));
        require(s, 'Transfer error');
    }

    function contractUsdtBalance() public view onlyOwner returns (uint) {
        return ERC20Interface(usdContractAddress).balanceOf(address(this));
    }

    function calculateAllTokens() public view returns (uint256 tokensAmount, uint256 withdrawed, uint256 usdtAmount) {
        for (uint256 i = 1; i <= PrivateSaleNft8FContractV1(nftContractAddress).currentTokenId(); i++) {
            Payment memory payment = this.getPayment(i);
            tokensAmount += payment.tokensAmount;
            withdrawed += payment.withdrawed;
            usdtAmount += payment.amount;
        }
    }

    function setStakeContractAddress(address _stakeContractAddress) public onlyOwner {
        stakeContractAddress = _stakeContractAddress;
    }

    function setTgePercent(uint value) public onlyOwner {
        tgePercent = value;
    }

    function setDefaultImageMaximumAmount(uint amount) public onlyOwner {
        defaultImageMaximumAmount = amount;
    }

    function setMinAmountForEntry(uint256 amount) public onlyOwner {
        minAmountForEntry = amount;
    }

    function withdrawTokens() public onlyOwner {
        uint byBalance = ERC20Interface(tokenAddress).balanceOf(address(this));
        (bool s,) = tokenAddress.call(abi.encodeWithSelector(bytes4(keccak256(bytes('transfer(address,uint256)'))), tx.origin, byBalance));
        require(s, 'Transfer error');
    }

    function setMaxCountBaseNft(uint amount) public onlyOwner {
        maxCountBaseNft = amount;
    }

    function updateNftCounts() public onlyOwner {
        currentDefaultNft = 0;
        currentExpensiveNft = 0;
        for (uint256 i = 1; i <= PrivateSaleNft8FContractV1(nftContractAddress).currentTokenId(); i++) {
            Payment memory payment = this.getPayment(i);
            if (payment.amount < defaultImageMaximumAmount) {
                currentDefaultNft++;
            } else {
                currentExpensiveNft++;
            }
        }
    }

}