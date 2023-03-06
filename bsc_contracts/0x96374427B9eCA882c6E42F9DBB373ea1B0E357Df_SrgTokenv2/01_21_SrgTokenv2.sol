//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";

import "./Illumipresale.sol";
import "./ColdStaking.sol";

//GOld list for presale
interface IPresalev1 {
    function goldList(address _addr) external view returns (bool);
}

/**
 * @author Lumishare
 *
 * @notice Main contract that has the logic of the presale
 */
contract SrgTokenv2 is
    ERC20,
    Ownable,
    Illumipresale,
    ColdStaking,
    ERC20Permit,
    ERC20Votes
{
    uint256 public constant MAX_SUPPLY = 7951696555 ether;
    uint256 public supply;
    uint256 public transferFee;
    address public coldStakingAddress;

    IPresalev1 immutable presalev1Contract;

    bool public pausedTransfers;

    mapping(address => bool) public whitelist;

    mapping(address => bool) public blacklist;

    mapping(address => bool) public freeTransferlist;

    mapping(address => bool) public preSellParticipant;

    event TransferFeeSet(uint256 fee);

    event AddedToWhitelist(address indexed account);
    event RemovedFromWhitelist(address indexed account);
    event AddedToBlacklist(address indexed account);
    event RemovedFromBlacklist(address indexed account);
    event AddedToFreeList(address indexed account);
    event RemovedFromFreeList(address indexed account);
    event NativeWithdrawn(uint256 amount);
    event AddedToAdminlist(address indexed account);
    event RemovedFromAdminlist(address indexed account);
    event BalanceAddedToPresale(uint256 amount);
    event BalanceWithdrawnFromPresale(uint256 amount);
    event AirdropClaimed(address indexed account, uint256 amount);

    event TokensWithdrawn(address token, address recipient, uint256 amount);

    event TransfersPaused();

    event TransfersResumed();

    IERC20 immutable srgTokenV1;

    /**
     * @param multiSigWallet - the address of the gnosis safe that will control the tokens
     * @param _srgTokenV1 - address of the old SRG Token for the claimable airdrop
     */

    constructor(
        address multiSigWallet,
        address _srgTokenV1,
        address priceFeedAddress,
        address[] memory acceptedStableCoins,
        address preSalev1
    )
        ERC20("Lumishare", "LUMI")
        Illumipresale(priceFeedAddress, acceptedStableCoins, 83333333 ether)
        ColdStaking((MAX_SUPPLY * 5) / 100)
        ERC20Permit("LumiShare LUMI")
    {
        transferFee = 0;
        srgTokenV1 = IERC20(_srgTokenV1);

        // everything will be minted for the token address, multisig will airdrop his old balance
        _mint(address(this), MAX_SUPPLY);

        whitelist[multiSigWallet] = true;
        whitelist[address(this)] = true;
        freeTransferlist[multiSigWallet] = true;

        //TBD if the presell has a fee or not
        freeTransferlist[address(this)] = true;

        addAdminlist(multiSigWallet);
        addAdminlist(msg.sender);
        //Transfers are locked until we decide when user can sell and add liquidity
        pausedTransfers = true;

        referralActive = true;
        transferOwnership(multiSigWallet);

        //For now only stablecoins are used for buying LUMI token
        pausedNatSell = true;

        // No gold list by default
        openSell = true;

        presalev1Contract = IPresalev1(preSalev1);
    }

    /**
     * @notice Burns SRG Tokens
     *
     * @param amount - Amount of tokens to be burned
     */
    function burn(uint256 amount) external returns (bool) {
        _burn(msg.sender, amount);

        return (true);
    }

    /**
     * @notice Sets the tax fee on transfers and transferFroms
     *
     * @param fee - SRG token Transaction fee
     */
    function setTransferFee(uint256 fee) external onlyOwner returns (bool) {
        // 1000 = 100% // WE DIVIDE BY 100000
        // 18 = 0.018%
        // 180 = 0.18%

        require(fee <= 180, "Fee can't be higher than 1.8 percent");

        transferFee = fee;

        emit TransferFeeSet(fee);
        return (true);
    }

    /**
     * @notice Withdraw any IERC20 tokens accumulated in this contract
     *
     * @param token - Address of token contract
     */
    function withdrawTokens(IERC20 token) external onlyOwner {
        uint256 transferAmount = token.balanceOf(address(this));
        if (address(token) == address(this)) {
            transferAmount -= _totalReward;
        }
        token.transfer(owner(), transferAmount);
        emit TokensWithdrawn(address(token), owner(), transferAmount);
    }

    function getTransferFee() external view returns (uint256) {
        return (transferFee);
    }

    // ERC20 Functions

    function transfer(address to, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        if (freeTransferlist[_msgSender()]) {
            _transfer(_msgSender(), to, amount);
        } else {
            _transferWithFees(_msgSender(), to, amount);
        }
        emit Transfer(msg.sender, to, amount);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        if (freeTransferlist[from]) {
            _transfer(from, to, amount);
        } else {
            _transferWithFees(from, to, amount);
        }
        uint256 currentAllowance = allowance(from, _msgSender());
        require(
            currentAllowance >= amount,
            "ERC20: transfer amount exceeds allowance"
        );
        _approve(from, _msgSender(), currentAllowance - amount);

        emit Transfer(from, to, amount);

        return true;
    }

    function _transferWithFees(
        address from,
        address to,
        uint256 amount
    ) private {
        require(balanceOf(from) >= amount, "Balance is too low");
        uint256 fee = (amount * (transferFee)) / (100000); // 0.018% starting
        uint256 afterFee = amount - (fee);

        _transfer(from, to, afterFee);
        _transfer(from, owner(), fee);
    }

    // Function to add an address to the whitelist
    function addToWhitelist(address account) public onlyOwner {
        whitelist[account] = true;
        emit AddedToWhitelist(account);
    }

    // Function to remove an address from the whitelist
    function removeFromWhitelist(address account) public onlyOwner {
        delete whitelist[account];
        emit RemovedFromWhitelist(account);
    }

    // Function to add an address to the whitelist
    function addtoBlacklist(address account) public onlyOwner {
        blacklist[account] = true;
        emit AddedToBlacklist(account);
    }

    // Function to remove an address from the whitelist
    function removeFromBlacklist(address account) public onlyOwner {
        delete blacklist[account];
        emit RemovedFromBlacklist(account);
    }

    // Function to add an address to the freeTransferlist
    function addToFreeList(address account) public onlyOwner {
        freeTransferlist[account] = true;
        emit AddedToFreeList(account);
    }

    // Function to remove an address from the freeTransferlist
    function removeFromFreeList(address account) public onlyOwner {
        delete freeTransferlist[account];
        emit RemovedFromFreeList(account);
    }

    /**
     * @notice Claim Airdrop function to burn old tokens and send new tokens to the caller
     * @dev Users that interacted with presale goldlist will receive extra fees,
     */
    function claimAirdrop() public {
        uint256 missingFees = 162; // 0.018 - 0.00018 = 0.0162  162/10000 = 0.0162

        // Check that the user held tokens at the time of the snapshot around 30 days when presale ended
        require(
            srgTokenV1.balanceOf(msg.sender) > 0,
            "User can not claim airdrop"
        );

        // Check the balance of the old contract for the caller
        uint256 oldBalance = srgTokenV1.balanceOf(msg.sender);

        // Burn the old tokens by transferring them to the address 0x0 (which is a reserved address that will never be used)
        require(
            srgTokenV1.transferFrom(msg.sender, address(0xdead), oldBalance),
            "Error burning old tokens"
        );

        // Send the new tokens to the caller

        uint256 newBalance = presalev1Contract.goldList(msg.sender)
            ? oldBalance + (oldBalance * missingFees) / 10000
            : oldBalance;

        require(
            IERC20(address(this)).transfer(msg.sender, newBalance),
            "Error sending new tokens"
        );

        emit AirdropClaimed(msg.sender, newBalance);
    }

    // Function to pause transfers
    function pauseTransfers() public onlyOwner {
        pausedTransfers = true;
        emit TransfersPaused();
    }

    // Function to unpause transfers
    function unpauseTransfers() public onlyOwner {
        pausedTransfers = false;
        emit TransfersResumed();
    }

    /**
     * @notice Before hook to effectively lock tokens depending of what we want

     *
     */
    function _beforeTokenTransfer(
        address from,
        address,
        uint256 amount
    ) internal virtual override {
        if (from != address(0x0)) {
            require(
                !pausedTransfers || whitelist[from],
                "Transfers are currently paused"
            );
            require(!blacklist[from], "Transfers are currently paused");

            require(
                balanceOf(from) >= stakedBalance[from] + amount,
                "Not enough unlocked"
            );
        }
    }

    /*@notice DAO methods
    // The following functions are overrides required by Solidity.
    */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override(ERC20, ERC20Votes) {
        super._afterTokenTransfer(from, to, amount);
    }

    function _mint(address to, uint256 amount)
        internal
        override(ERC20, ERC20Votes)
    {
        super._mint(to, amount);
    }

    function _burn(address account, uint256 amount)
        internal
        override(ERC20, ERC20Votes)
    {
        super._burn(account, amount);
    }
}