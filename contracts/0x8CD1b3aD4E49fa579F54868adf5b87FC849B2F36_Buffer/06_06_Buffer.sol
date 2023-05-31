// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;
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
//Payment splitter contract for existing collections - single artist
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract Buffer is Initializable {
    using ECDSA for bytes32;

    event PaymentWithdrawn(address indexed member, uint256 indexed amount);
    event PaymentRecieved (address indexed sender, uint256 rtype, uint256 indexed amount);
    error TransferFailed();

    struct Pie {
        uint16 coreTeamPerc; //uint16
        // uint16 artistPerc; //uint16
        // uint16 singleSalePerc; //uint16
        uint16 allHoldersPerc; //uint16
        uint16 montagePerc; //uint16
        // uint96 ethBalance; //uint96
        uint96 totalClaimed; //uint96
        mapping(address => uint256) earningsClaimed; // u128
        mapping(address => uint256) donationsClaimed; // u128
    }

    Pie private sales;
    address[] private coreTeam;
    uint16[] private coreTeamPercents;
    address owner;
    address signer;
    address admin;

    address immutable montage = 0xE4068ba8805e307f0bC129ddE8c0E25A46AE583f;

    modifier onlyOwner() {
        require(owner == msg.sender, "Caller is not the owner.");
        _;
    }
    modifier onlyOwnerOrAdmin() {
        require(
            msg.sender == owner || msg.sender == admin,
            "Ownable: caller is not authorized"
        );
        _;
    }

    function initialize(
        uint16[3] memory _percents,
        address[] memory _coreTeam,
        uint16[] memory _coreTeamPercents,
        address _owner
    ) public payable initializer {
        require(_percents[0] + _percents[1] + _percents[2] == 10000, "Sum of percents must be 10000 BPS");
        require(coreTeam.length == coreTeamPercents.length, "invalid team input");
        if (coreTeam.length > 0) {
            require(sum(_coreTeamPercents) == 10000, "Sum of coreTeamPercents must be 10000 BPS");
        }
        sales.allHoldersPerc = _percents[0];
        sales.montagePerc = _percents[1];
        sales.coreTeamPerc = _percents[2];
        coreTeam = _coreTeam;
        coreTeamPercents = _coreTeamPercents;
        owner = _owner;
    }

    receive() external payable {
        emit PaymentRecieved(
            msg.sender, 
            2, // - sales
            msg.value
        );
        if (sales.montagePerc > 0) {
            uint256 montageFee = msg.value * sales.montagePerc / 10000;
            sales.earningsClaimed[montage] += montageFee;
            sales.totalClaimed += uint96(montageFee);
            _transfer(montage, montageFee);
            emit PaymentWithdrawn(montage, montageFee);
        }
    }

    /// @notice creats a hash of current deployed chain id and current contract address
    /// @dev appended to hash of signature to prevent replay attacks on other contract instances
    /// @return bytes32
    function hashContractInfo() public view returns (bytes32) {
        return keccak256(abi.encode(block.chainid, address(this)));
    }

    /// @notice hashes a holder claim for signature recovery
    /// @dev prepends contract info hash to prevent replay attacks
    /// @param claimable uint256 amount to send
    /// @param holder address of holder to claim
    /// @return bytes32
    function hashPayoutMessage(uint256 claimable, address holder)
        public
        view
        returns (bytes32)
    {
        return
            keccak256(
                abi.encode(
                    hashContractInfo(),
                    keccak256(abi.encode(claimable, holder))
                )
            );
    }

    /// @notice internal function to validate an admin signature
    /// @dev uses hashPayoutMessage and openzeppelin ECDSA toEthSignedMessageHash function to generate comparison
    /// @param claimable uint256 amount to send
    /// @param holder address of holder to claim
    /// @param signature auth signature of parameters
    function validateSignature(
        uint256 claimable,
        address holder,
        bytes memory signature
    ) internal view {
        bytes32 hashed = hashPayoutMessage(claimable, holder);
        address recovered = hashed.toEthSignedMessageHash().recover(signature);
        require(recovered == signer, "invalid signature");
    }

    /// @notice sets the signer address
    /// @dev only callable by  owner. need for signer based sale royalty distribution
    function setSigner(address _s) external onlyOwner {
        signer = _s;
    }

    /// @notice sets the signer address
    /// @dev only callable by  owner. need for signer based sale royalty distribution
    function setAdmin(address _a) external onlyOwner {
        admin = _a;
    }

    function viewTotalDonated(address member) external view returns(uint256) {
        return sales.donationsClaimed[member];
    }

    function getSalesTotalClaimed() external view returns(uint96) {
        return sales.totalClaimed;
    }
    function getSalesAllHoldersPerc() external view returns(uint16) {
        return sales.allHoldersPerc;
    }

    function holderDonate(address payable donateTo, uint256 _holderPayout, bytes memory signature) external {
        address holder = msg.sender;
        validateSignature(_holderPayout, holder, signature);
        uint256 ethBalance = address(this).balance;
        uint256 claimableShare = ((ethBalance + sales.totalClaimed) * sales.allHoldersPerc) / 10000;
        require(_holderPayout < claimableShare, "invalid _holderPayout");
        require(_holderPayout > sales.donationsClaimed[holder], "new payout amount must be more than claimed");

        uint256 payout = _holderPayout - sales.donationsClaimed[holder];
        sales.donationsClaimed[holder] += payout;
        sales.totalClaimed += uint96(payout);
        _transfer(donateTo, payout);
        emit PaymentWithdrawn(holder, payout);
    }

    function viewTotalWithdrawn(address member) external view returns(uint256) {
        return sales.earningsClaimed[member];
    }
    function viewEarnings(address member) external view returns(uint256) {
        return getEarningsPayoutFrom(member);
    } 
    function withdraw() external {
        address member = msg.sender;
        uint96 payout = uint96(getEarningsPayoutFrom(member));
        require(payout > 0, "Insufficient balance.");
        sales.earningsClaimed[member] += payout;
        sales.totalClaimed += payout;
        _transfer(member, payout);
        emit PaymentWithdrawn(member, payout);
    }
    function getEarningsPayoutFrom(address member) internal view returns(uint256) {
        uint256 ethBalance = address(this).balance;
        uint256 allTeamShareClaimable = ((ethBalance + sales.totalClaimed) * sales.coreTeamPerc) / 10000;
        uint256 index = findCoreTeamIndex(member, coreTeam);
        uint256 memberShareClaimable = index < coreTeamPercents.length ? (coreTeamPercents[index] * allTeamShareClaimable) / 10000 : 0;
        uint256 payout = memberShareClaimable > sales.earningsClaimed[member] ? memberShareClaimable - sales.earningsClaimed[member] : 0;
        return payout;
    }
    
    function findCoreTeamIndex(address member, address[] memory _coreTeam) internal pure returns(uint256) {
        for (uint256 i = 0; i < _coreTeam.length; i++) {
            if (member == _coreTeam[i]) {
                return i;
            }
        }
        return _coreTeam.length;
    }

    function sum(uint16[] memory values) internal pure returns (uint16 result) {
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