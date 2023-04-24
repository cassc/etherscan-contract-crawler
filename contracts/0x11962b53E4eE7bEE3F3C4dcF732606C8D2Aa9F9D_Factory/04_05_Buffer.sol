//SPDX-License-Identifier: MIT
pragma solidity 0.8.16;
//-- _____ ______    ________   ________    _________   ________   ________   _______      
//--|\   _ \  _   \ |\   __  \ |\   ___  \ |\___   ___\|\   __  \ |\   ____\ |\  ___ \     
//--\ \  \\\__\ \  \\ \  \|\  \\ \  \\ \  \\|___ \  \_|\ \  \|\  \\ \  \___| \ \   __/|    
//-- \ \  \\|__| \  \\ \  \\\  \\ \  \\ \  \    \ \  \  \ \   __  \\ \  \  ___\ \  \_|/__  
//--  \ \  \    \ \  \\ \  \\\  \\ \  \\ \  \    \ \  \  \ \  \ \  \\ \  \|\  \\ \  \_|\ \ 
//--   \ \__\    \ \__\\ \_______\\ \__\\ \__\    \ \__\  \ \__\ \__\\ \_______\\ \_______\
//--    \|__|     \|__| \|_______| \|__| \|__|     \|__|   \|__|\|__| \|_______| \|_______|
//--                                                                                       
//-- 
//-- Montage.io   
//Montage NFT payment splitter contract for evolving collections - single artist

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

interface NFTContract {
    function balanceOf(address owner) external view returns (uint256 balance);
    function getTotalSupply() external view returns (uint256);
}

contract Buffer is Initializable {

    NFTContract private _nftContract;

    event PaymentWithdrawn(address indexed member, uint256 indexed amount);
    event PaymentRecieved (address indexed sender, uint256 rtype, uint256 indexed amount);
    error TransferFailed();

    modifier onlyOwner() {
        require(owner == msg.sender, "Caller is not the owner.");
        _;
    }
    modifier whenNotPaused() {
        require(!paused, "Pausable: paused");
        _;
    }
    modifier onlyOwnerOrAdmin() {
         require(msg.sender == owner || msg.sender == admin, "Ownable: caller is not authorized");
        _;
    }

    struct Pie {
        uint256 coreTeamPerc;
        uint256 allHoldersPerc;
        uint256 montagePerc;
        uint256 ethBalance;
        uint256 totalClaimed;
        mapping(address => uint256) earningsClaimed;
        mapping(address => uint256) donationsClaimed;
    }

    mapping(address => uint256) coreTeamPercents;
    Pie public mint;
    Pie public sales;

    bool public paused;
    address public owner;
    address public admin;
    address immutable montage = 0xE4068ba8805e307f0bC129ddE8c0E25A46AE583f;
    

    function initialize(address _owner) public payable initializer {
        owner = _owner;
    }

    receive() external payable {
        bool isMint = msg.sender == address(_nftContract);
        uint256 rType;
        uint256 montageFee;
        if (isMint) {
            rType = 1; // mint
            montageFee = msg.value * mint.montagePerc / 10000;
            mint.ethBalance += msg.value;
            if (montageFee > 0) {
                mint.ethBalance -= montageFee;
                mint.totalClaimed += montageFee;
                mint.earningsClaimed[montage] += montageFee;
            }
        } else {
            rType = 2; // sales
            montageFee = msg.value * sales.montagePerc / 10000;
            sales.ethBalance += msg.value;
            if (montageFee > 0) {
                sales.ethBalance -= montageFee;
                sales.totalClaimed += montageFee;
                sales.earningsClaimed[montage] += montageFee;
            }
        }
        if (montageFee > 0) {
            _transfer(montage, montageFee);
        }
        emit PaymentRecieved(msg.sender, rType, msg.value);
    }

    function setPaused(bool _paused) public onlyOwnerOrAdmin {
        paused = _paused;
    }

    function setAdmin(address _admin) external onlyOwner {
        admin = _admin;
    }

    function viewTotalWithdrawn(address member) external view returns(uint256) {
        return mint.earningsClaimed[member] + sales.earningsClaimed[member];
    }

    function viewTotalDonated(address member) external view returns(uint256) {
        return mint.donationsClaimed[member] + sales.donationsClaimed[member];
    }

    function setPercentsAndAddCoreTeam(
        uint256[] calldata values,
        address[] calldata coreTeamAddresses,
        uint256[] calldata c_teamPercs
    ) external payable onlyOwnerOrAdmin {
        require(values.length == 10, "There must be 10 uint256 values for the percentages");
        require(sum(values) == 20000, "Sum of values arg must be 20000 BPS");
        sales.coreTeamPerc = values[0];
        // sales.allArtistsPerc = values[1];
        // sales.singleArtistPerc = values[2];
        sales.allHoldersPerc = values[3];
        sales.montagePerc = values[4];
        mint.coreTeamPerc = values[5];
        // mint.allArtistsPerc = values[6];
        // mint.singleArtistPerc = values[7];
        mint.allHoldersPerc = values[8];
        mint.montagePerc = values[9];

        if (coreTeamAddresses.length > 0) {
            require(coreTeamAddresses.length == c_teamPercs.length, "Each team member needs a share % in BPS format");
            require(sum(c_teamPercs) == 10000, "Sum of core team percents must be 10000 BPS");
            for (uint i; i < coreTeamAddresses.length; i++) {
                coreTeamPercents[coreTeamAddresses[i]] = c_teamPercs[i];
            }
        }
    }

    function setNftAddress(address nft) external onlyOwnerOrAdmin {
        _nftContract = NFTContract(nft);
    }

    function viewDonationAmt(address member) external view returns(uint256) {
        return getDonationPayoutFrom(member, mint) + getDonationPayoutFrom(member, sales);
    }
    function viewEarnings(address member) external view returns(uint256) {
        return getEarningsPayoutFrom(member, mint) + getEarningsPayoutFrom(member, sales);
    }    

	function withdraw() external whenNotPaused {
        address member = msg.sender;
        uint256 mintPayout = getEarningsPayoutFrom(member, mint);
        uint256 salesPayout = getEarningsPayoutFrom(member, sales);
        uint256 payout = mintPayout + salesPayout;
        require(payout > 0, "Insufficient balance.");
        mint.ethBalance -= mintPayout;
        mint.earningsClaimed[member] += mintPayout;
        mint.totalClaimed += mintPayout;
        sales.ethBalance -= salesPayout;
        sales.earningsClaimed[member] += salesPayout;
        sales.totalClaimed += salesPayout;
        _transfer(member, payout);
        emit PaymentWithdrawn(member, payout);
    }
    function holderDonate(address payable donateTo) external whenNotPaused {
        address member = msg.sender;
        uint256 mintPayout = getDonationPayoutFrom(member, mint);
        uint256 salesPayout = getDonationPayoutFrom(member, sales);
        uint256 payout = mintPayout + salesPayout;
        require(payout > 0, "Insufficient balance.");
        mint.ethBalance -= mintPayout;
        mint.donationsClaimed[member] += mintPayout;
        mint.totalClaimed += mintPayout;
        sales.ethBalance -= salesPayout;
        sales.donationsClaimed[member] += salesPayout;
        sales.totalClaimed += salesPayout;
        _transfer(donateTo, payout);
        emit PaymentWithdrawn(member, payout);
    }		

    function getEarningsPayoutFrom(address member, Pie storage pie) internal view returns(uint256) {
        uint256 claimed = pie.earningsClaimed[member];
        uint256 claimable = ((pie.ethBalance + pie.totalClaimed) * pie.coreTeamPerc) / 10000;
        uint256 memberShare = (claimable * coreTeamPercents[member]) / 10000;
        uint256 payout = memberShare > claimed ? memberShare - claimed : 0;
        return payout;
    }

    function getDonationPayoutFrom(address member, Pie storage pie) internal view returns(uint256) {
        uint256 claimable = ((pie.ethBalance + pie.totalClaimed) * pie.allHoldersPerc) / 10000;
        uint256 totalMinted = _nftContract.getTotalSupply() - 1;
        uint256 memberShare = totalMinted > 0 ? (claimable * _nftContract.balanceOf(member)) / totalMinted : 0;
        uint256 claimed = pie.donationsClaimed[member];
        uint256 payout = memberShare > claimed ? memberShare - claimed : 0;
        return payout;
    }

    function sum(uint256[] memory values) internal pure returns (uint256 result) {
        for (uint i = 0; i < values.length; i++) {
            result += values[i];
        }
    }

    // adopted from https://github.com/lexDAO/Kali/blob/main/contracts/libraries/SafeTransferLib.sol
    function _transfer(address to, uint256 amount) internal {
        bool callStatus;
        assembly {
            callStatus := call(gas(), to, amount, 0, 0, 0, 0)
        }
        if (!callStatus) revert TransferFailed();
    }
}