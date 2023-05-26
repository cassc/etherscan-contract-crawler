//SPDX-License-Identifier: MIT
pragma solidity 0.8.16;
//-- _____ ______ ________ ________ _________ ________ ________ _______
//--|\ _ \ _ \ |\ __ \ |\ ___ \ |\___ ___\|\ __ \ |\ ____\ |\ ___ \
//--\ \ \\\__\ \ \\ \ \|\ \\ \ \\ \ \\|___ \ \_|\ \ \|\ \\ \ \___| \ \ __/|
//-- \ \ \\|__| \ \\ \ \\\ \\ \ \\ \ \ \ \ \ \ \ __ \\ \ \ ___\ \ \_|/__
//-- \ \ \ \ \ \\ \ \\\ \\ \ \\ \ \ \ \ \ \ \ \ \ \\ \ \|\ \\ \ \_|\ \
//-- \ \__\ \ \__\\ \_______\\ \__\\ \__\ \ \__\ \ \__\ \__\\ \_______\\ \_______\
//-- \|__| \|__| \|_______| \|__| \|__| \|__| \|__|\|__| \|_______| \|_______|
//--
//--
//-- Montage.io
//Montage NFT payment splitter contract for  many artists / evolving collection / fixed prices

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "hardhat/console.sol";

interface NFTContract {
    function balanceOf(address owner) external view returns (uint256 balance);

    function getTotalMinted(address artist) external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function totalArtists() external view returns (uint16);

    function isArtist(address a) external view returns (bool);
    //function artistInfo(address a) external view returns (bool,uint16);
}

contract Buffer is Initializable {
    using ECDSA for bytes32;
    NFTContract private _nftContract;

    event PaymentWithdrawn(address indexed member, uint256 indexed amount);
    event PaymentRecieved(
        address indexed sender,
        uint256 rtype,
        uint256 indexed amount
    );
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
        require(
            msg.sender == owner || msg.sender == admin,
            "Ownable: caller is not authorized"
        );
        _;
    }
    // can optimize this struct for data storage
    struct Pie {
        uint16 coreTeamPerc; //uint16
        uint16 allArtistsPerc; //uint16
        uint16 singleArtistPerc; //uint16
        uint16 allHoldersPerc; //uint16
        uint16 montagePerc; //uint16
        uint96 ethBalance; //uint96
        uint96 totalClaimed; //uint96
        mapping(address => uint256) earningsClaimed; // u128
        mapping(address => uint256) donationsClaimed; // u128
    }

    mapping(address => uint256) coreTeamPercents;

    //mapping(address => bool) isArtist;
    Pie public mint;
    Pie public sales;

    bool public paused;
    address public owner;
    address public admin;
    address public signer;
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
            montageFee = (msg.value * mint.montagePerc) / 10000;
            mint.ethBalance += uint96(msg.value);
            if (montageFee > 0) {
                mint.ethBalance -= uint96(montageFee);
                mint.totalClaimed += uint96(montageFee);
                mint.earningsClaimed[montage] += uint96(montageFee);
            }
        } else {
            rType = 2; // sales
            montageFee = (msg.value * sales.montagePerc) / 10000;

            sales.ethBalance += uint96(msg.value);
            if (montageFee > 0) {
                sales.ethBalance -= uint96(montageFee);
                sales.totalClaimed += uint96(montageFee);
                sales.earningsClaimed[montage] += montageFee;
            }
        }
        if (montageFee > 0) {
            _transfer(montage, montageFee);
        }
        emit PaymentRecieved(msg.sender, rType, msg.value);
    }

    /// @notice pauses the contract
    /// @dev only callable by admin or owner
    function setPaused(bool _paused) public onlyOwnerOrAdmin {
        paused = _paused;
    }

    /// @notice sets the admin
    function setAdmin(address _admin) external onlyOwner {
        admin = _admin;
    }

    /// @notice sets the signer address
    /// @dev only callable by  owner. need for signer based sale royalty distribution
    function setSigner(address _s) external onlyOwner {
        signer = _s;
    }

    /// @notice returns amoutn withdrawn by artist/team member
    function viewTotalWithdrawn(address member)
        external
        view
        returns (uint256)
    {
        return mint.earningsClaimed[member] + sales.earningsClaimed[member];
    }

    function viewTotalDonated(address member) external view returns (uint256) {
        return mint.donationsClaimed[member] + sales.donationsClaimed[member];
    }

    /// @notice sets payout percentages
    /// @dev percentages are represent by uints with 3 decimatls.checks percentages sum to 10000
    /// @param values uint16 array of legnth 5 for secondary sale royalty percents
    /// @param coreTeamAddresses array of addresses for coreteam
    /// @param c_teamPercs uint16 array split for core team
    function setPercentsAndAddCoreTeam(
        uint16[10] memory values,
        address[] memory coreTeamAddresses,
        uint16[] memory c_teamPercs
    ) external payable onlyOwnerOrAdmin {
        require(
            sumRange(values, 0, 5) == 10000,
            "Sum of the first 5 values must be 10000 BPS"
        );
        require(
            sumRange(values, 5, 10) == 10000,
            "Sum of second 5 values must be 10000 BPS"
        );
        sales.coreTeamPerc = values[0];
        sales.allArtistsPerc = values[1];
        sales.singleArtistPerc = values[2];
        sales.allHoldersPerc = values[3];
        sales.montagePerc = values[4];

        mint.coreTeamPerc = values[0];
        mint.allArtistsPerc = values[1];
        mint.singleArtistPerc = values[2];
        mint.allHoldersPerc = values[3];
        mint.montagePerc = values[4];

        if (coreTeamAddresses.length > 0) {
            require(
                coreTeamAddresses.length == c_teamPercs.length,
                "Each team member needs a share % in BPS format"
            );
            require(
                sum(c_teamPercs) == 10000,
                "Sum of core team percents must be 10000 BPS"
            );
            for (uint256 i; i < coreTeamAddresses.length; i++) {
                coreTeamPercents[coreTeamAddresses[i]] = c_teamPercs[i];
            }
        }
    }

    /// @notice sets nft contract address needed to check artist membership and mint counts
    /// @dev can only be called by owner or admin
    /// @param nft address of nft contract
    function setNftAddress(address nft) external onlyOwnerOrAdmin {
        _nftContract = NFTContract(nft);
    }

    function getNftAddress() external view returns (address) {
        return address(_nftContract);
    }

    /// @notice returns withdrawable donation amount
    /// @dev
    /// @param member address of member
    function viewDonationAmt(address member) external view returns (uint256) {
        return
            getDonationPayoutFrom(member, mint) +
            getDonationPayoutFrom(member, sales);
    }

    /// @notice returns withdrawable earnings
    /// @dev
    /// @param member address of member
    function viewEarnings(address member) external view returns (uint256) {
        return
            getEarningsPayoutFromMint(member, mint) +
            getEarningsPayoutFrom(member, sales);
    }

    /// @notice withdraw function for artists and team members
    /// @dev calculates payouts from initial mints and flat sale payouts but not id specific secondary sale artist
    function withdraw() external whenNotPaused {
        address member = msg.sender;
        uint96 mintPayout = uint96(getEarningsPayoutFromMint(member, mint));
        uint96 salesPayout = uint96(getEarningsPayoutFrom(member, sales));
        uint256 payout = uint256(mintPayout + salesPayout);
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

    /// @notice donation function for holders
    /// @param donateTo address of donation recipient
    function holderDonate(address payable donateTo) external whenNotPaused {
        address member = msg.sender;
        uint96 mintPayout = uint96(getDonationPayoutFrom(member, mint));
        uint96 salesPayout = uint96(getDonationPayoutFrom(member, sales));
        uint96 payout = mintPayout + salesPayout;
        require(payout > 0, "Insufficient balance.");
        mint.ethBalance -= mintPayout;
        mint.donationsClaimed[member] += mintPayout;
        mint.totalClaimed += mintPayout;
        sales.ethBalance -= salesPayout;
        sales.donationsClaimed[member] += salesPayout;
        sales.totalClaimed += salesPayout;
        _transfer(donateTo, uint256(payout));
        emit PaymentWithdrawn(member, uint256(payout));
    }

    /// @notice allows an artist to claim a royalty percentage based on secondary sales of their nfts
    /// @dev permissioned function via authority signaure. Artist payout amounts must calculated offchain based on sale api
    /// @param claimable amount that can be claimed. This must be the total historical Amount calculated from the api. Payout calculation is based on this assumption
    /// @param artist address of artist to receive royalty
    /// @param signature signature by signer address of the hash of (claimable,artst). See hashPayoutMessage functionf or hashing details
    function artistSaleClaim(
        uint256 claimable,
        address artist,
        bytes memory signature
    ) external whenNotPaused {
        //require(msg.sender == artist, "artist must initiate withdraw");
        validateSignature(claimable, artist, signature);
        uint256 payout = calculate_payout(claimable, msg.sender);
        //console.log(payout, "payout amount");
        sales.totalClaimed += uint96(payout);
        sales.ethBalance -= uint96(payout);
        _transfer(msg.sender, payout);
    }

    /// @notice allows an admin  to send out an artists  royalty percentage based on secondary sales of the artist nfts
    /// @dev can only be called by admin or owner
    /// @param claimable amount that can be claimed
    /// @param artist address of artist to receive royalty
    function artistSalePayout(uint256 claimable, address artist)
        external
        onlyOwnerOrAdmin
    {
        uint256 payout = calculate_payout(claimable, artist);
        sales.totalClaimed += uint96(payout);
        sales.ethBalance -= uint96(payout);
        _transfer(msg.sender, payout);
    }

    /// @notice creats a hash of current deployed chain id and current contract address
    /// @dev appended to hash of signature to prevent replay attacks on other contract instances
    /// @return bytes32
    function hashContractInfo() public view returns (bytes32) {
        return keccak256(abi.encode(block.chainid, address(this)));
    }

    /// @notice hashes an artist claim for signature recovery
    /// @dev prepends contract info hash to prevent replay attacks
    /// @param claimable uint256 amount to send
    /// @param artist address of artist to claim
    /// @return bytes32
    function hashPayoutMessage(uint256 claimable, address artist)
        public
        view
        returns (bytes32)
    {
        return
            keccak256(
                abi.encode(
                    hashContractInfo(),
                    keccak256(abi.encode(claimable, artist))
                )
            );
    }

    /// @notice internal function to calcuate artist earnings in secondary sales
    /// @dev subtracts amount from already claimed amount.If amount is not large than claimed then no new amount is sent.Amount is meant to be total claims at the current point in time.
    /// @param amount uint256 amount for new claim
    /// @param artist address of artist to claim
    function calculate_payout(uint256 amount, address artist)
        internal
        returns (uint256)
    {
        uint256 claimed = sales.earningsClaimed[artist];

        sales.earningsClaimed[artist] += (amount - claimed);

        return amount - claimed;
    }

    /// @notice internal function to validate an admin signature
    /// @dev uses hashPayoutMessage and openzeppelin ECDSA toEthSignedMessageHash function to generate comparison
    /// @param claimable uint256 amount to send
    /// @param artist address of artist to claim
    /// @param signature hash message signed by signer address; the hash is the result of hashPayoutMessage(claimable, artist)
    function validateSignature(
        uint256 claimable,
        address artist,
        bytes memory signature
    ) internal view {
        bytes32 hashed = hashPayoutMessage(claimable, artist);
        address recovered = hashed.toEthSignedMessageHash().recover(signature);
        require(recovered == signer, "invalid signature");
    }

    /// @notice internal function to calculate royalty payout base on core team and fixed artist sale share
    /// @dev
    /// @param member address of member to claim
    /// @param pie reference to either mint or sales percent data
    function getEarningsPayoutFrom(address member, Pie storage pie)
        internal
        view
        returns (uint256)
    {
        uint256 claimed = pie.earningsClaimed[member];
        uint256 claimable = ((pie.ethBalance + pie.totalClaimed) *
            pie.coreTeamPerc) / 10000;
        uint256 memberShare = (claimable * coreTeamPercents[member]) / 10000;
        if (_nftContract.isArtist(member)) {
            memberShare +=
                ((pie.ethBalance + pie.totalClaimed) * (pie.singleArtistPerc)) /
                (10000 * _nftContract.totalArtists());
        }
        uint256 payout = memberShare > claimed ? memberShare - claimed : 0;
        return payout;
    }

    /// @notice internal function to calculate royalty payout including team,fixed singleArtistShare and mint based allArtistsPerc
    /// @dev allArtistsPerc is split based on ratio of artist minted nfts to total
    /// @param member address of member to claim
    /// @param pie reference to either mint or sales percent data
    function getEarningsPayoutFromMint(address member, Pie storage pie)
        internal
        view
        returns (uint256)
    {
        uint256 claimed = pie.earningsClaimed[member];

        uint256 teamClaimable = ((pie.ethBalance + pie.totalClaimed) *
            (pie.coreTeamPerc)) / 10000;
        //team claim
        uint256 totalShare = (teamClaimable * coreTeamPercents[member]) / 10000;

        uint256 artistClaimable = ((pie.ethBalance + pie.totalClaimed) *
            (pie.allArtistsPerc)) / 10000;
        console.log(pie.allArtistsPerc, "artist perc");

        if (_nftContract.isArtist(member)) {
            console.log(pie.singleArtistPerc, "flat sale perc");

            console.log(_nftContract.totalArtists());
            // single artist share
            totalShare +=
                ((pie.ethBalance + pie.totalClaimed) * (pie.singleArtistPerc)) /
                (10000 * _nftContract.totalArtists());

            console.log(totalShare, "total share from flat");
            //  mint share
            totalShare += getArtistMintedShare(member, artistClaimable);

            console.log(totalShare, "total share with mint");
        }
        //console.log(artistClaimable, "claimable");

        uint256 payout = totalShare > claimed ? totalShare - claimed : 0;
        return payout;
    }

    /// @notice calculates an artists share base on their percentage of total minted nfts
    /// @dev calls nft totalSupply and getTotalMinted functions to get data
    function getArtistMintedShare(address artist, uint256 share)
        internal
        view
        returns (uint256)
    {
        uint256 totalMinted = _nftContract.totalSupply();

        uint256 artistMinted = _nftContract.getTotalMinted(artist);

        return ((artistMinted * share) / totalMinted);
    }

    /// @notice calcuates donation payout based on nft balance
    function getDonationPayoutFrom(address member, Pie storage pie)
        internal
        view
        returns (uint256)
    {
        uint256 claimable = ((pie.ethBalance + pie.totalClaimed) *
            pie.allHoldersPerc) / 10000;
        uint256 totalMinted = _nftContract.totalSupply();
        uint256 memberShare = totalMinted > 0
            ? (claimable * _nftContract.balanceOf(member)) / totalMinted
            : 0;
        uint256 claimed = pie.donationsClaimed[member];
        uint256 payout = memberShare > claimed ? memberShare - claimed : 0;
        return payout;
    }

    /// @notice calculates a sum over a uint16 array
    function sum(uint16[] memory values)
        internal
        pure
        returns (uint256 result)
    {
        for (uint256 i = 0; i < values.length; i++) {
            result += values[i];
        }
    }    
    
    /// @notice calculates a sum over a uint16 array range
    function sumRange(uint16[10] memory values, uint256 start, uint256 end)
        internal
        pure
        returns (uint256 result)
    {
        for (uint256 i = start; i < end; i++) {
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