// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./PlatformOwnable.sol";
import "./IDistribution.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract BalenseaReferral is Ownable, PlatformOwnable {
    address[] private masters;
    address[] private members;
    uint256 public royaltyTax;
    uint256 public commissionTax;
    uint256 public referralTax_kol; // kol referral
    uint256 public referralTax_master; // master referral
    uint256 public referralTax_l1; // user's upline
    uint256 public referralTax_l2; // user's upper upline

    // user address => referral address
    mapping(address => address) public referrals;

    event Register(address user, address referral);
    event AddMaster(address indexed newMaster);
    event SetRoyaltyTax(uint256 previousTax, uint256 newTax);
    event SetCommissionTax(uint256 previousTax, uint256 newTax);
    event SetReferralTax(
        string referralType,
        uint256 previousTax,
        uint256 newTax
    );

    struct InitialPayments {
        uint256 commissionPayment;
        uint256 royaltyPayment;
        uint256 masterPayment;
        uint256 referralL1Payment;
        uint256 referralL2Payment;
        uint256 remaining;
    }

    struct KOLPayments {
        uint256 commissionPayment;
        uint256 royaltyPayment;
        uint256 masterPayment;
        uint256 kolPayment;
        uint256 remaining;
    }

    modifier onlyNewUser() {
        require(
            referrals[_msgSender()] == address(0),
            "sender already registered"
        );
        _;
    }
    modifier validateReferral(address _referral) {
        require(_referral != address(0), "invalid referral");
        if (!isMaster(_referral)) {
            require(referrals[_referral] != address(0), "referral not exist");
        }
        _;
    }

    constructor(
        address _platformOwner,
        uint256 _royaltyTax,
        uint256 _commissionTax,
        uint256 _referralTax_kol,
        uint256 _referralTax_master,
        uint256 _referralTax_l1,
        uint256 _referralTax_l2,
        address[] memory _masters
    ) PlatformOwnable(_platformOwner) {
        require(_royaltyTax != 0, "royalty tax must not be 0");
        require(_commissionTax != 0, "commission tax must not be 0");
        require(_referralTax_kol != 0, "referral tax (kol) must not be 0");
        require(
            _referralTax_master != 0,
            "referral tax (master) must not be 0"
        );
        require(_referralTax_l1 != 0, "referral tax (l1) must not be 0");
        require(_referralTax_l2 != 0, "referral tax (l2) must not be 0");
        for (uint256 i = 0; i < _masters.length; i++) {
            require(_masters[i] != address(0), "Invalid master address");
        }

        royaltyTax = _royaltyTax;
        commissionTax = _commissionTax;
        referralTax_kol = _referralTax_kol;
        referralTax_master = _referralTax_master;
        referralTax_l1 = _referralTax_l1;
        referralTax_l2 = _referralTax_l2;
        masters = _masters;
    }

    // register as member of marketplace
    function register(address _referral)
        external
        onlyNewUser
        validateReferral(_referral)
    {
        // register as member
        members.push(_msgSender());

        // register referral
        referrals[_msgSender()] = _referral;

        emit Register(_msgSender(), _referral);
    }

    // add kol into member list
    // Note: referral for kol must be master address
    function registerKOL(address _master, address _kol) external onlyPlatformOwner {
        require(_master != address(0), "invalid master address");
        require(_kol != address(0), "invalid kol address");
        require(isMaster(_master), "master address is not master");
        require(!isMaster(_kol), "kol address cannot be master");
        require(!isMember(_kol), "kol address is one of the member");

        // register as member
        members.push(_kol);

        // register referral
        referrals[_kol] = _master;

        emit Register(_kol, _master);
    }

    // add new master referral
    function addMaster(address _master) external onlyPlatformOwner {
        require(_master != address(0), "invalid master address");
        require(!isMaster(_master), "master address exist");
        require(!isMember(_master), "this address is one of the member");

        masters.push(_master);
        emit AddMaster(_master);
    }

    function setRoyaltyTax(uint256 _newRoyaltyTax) external onlyPlatformOwner {
        require(_newRoyaltyTax > 0, "invalid royalty tax");

        uint256 previous = royaltyTax;
        royaltyTax = _newRoyaltyTax;
        emit SetRoyaltyTax(previous, _newRoyaltyTax);
    }

    function setCommissionTax(uint256 _newCommissionTax)
        external
        onlyPlatformOwner
    {
        require(_newCommissionTax > 0, "invalid commission tax");

        uint256 previous = commissionTax;
        commissionTax = _newCommissionTax;
        emit SetCommissionTax(previous, _newCommissionTax);
    }

    function setReferralTax(
        uint256 _kol,
        uint256 _master,
        uint256 _l1,
        uint256 _l2
    ) external onlyPlatformOwner {
        require(_kol > 0, "invalid kol referral tax");
        require(_master > 0, "invalid master referral tax");
        require(_l1 > 0, "invalid l1 referral tax");
        require(_l2 > 0, "invalid l2 referral tax");

        uint256 previous = referralTax_kol;
        referralTax_kol = _kol;
        emit SetReferralTax("kol", previous, _kol);

        previous = referralTax_master;
        referralTax_master = _master;
        emit SetReferralTax("master", previous, _master);

        previous = referralTax_l1;
        referralTax_l1 = _l1;
        emit SetReferralTax("l1", previous, _l1);

        previous = referralTax_l2;
        referralTax_l2 = _l2;
        emit SetReferralTax("l2", previous, _l2);
    }

    /**
     * calculate distributions for all the addresses (sub sales)
     *
     * Addresses involved:
     *    1. platform owner
     *    2. seller
     */
    function getSubDistributions(
        address _owner,
        address _buyer,
        uint256 _total
    ) external view returns (IDistribution.Sub memory) {
        require(_owner != address(0), "invalid owner address");
        require(_buyer != address(0), "invalid buyer address");
        require(_total > 0, "total value cannot be 0");

        uint256 commissionPayment = (_total * commissionTax) / 100;
        uint256 remaining = _total - commissionPayment;

        return
            IDistribution.Sub(
                platformOwner(),
                commissionPayment,
                _owner,
                remaining
            );
    }

    /**
     * calculate distributions for all the addresses (initial sales)
     *
     * Addresses involved:
     *    1. platform owner
     *    2. creator
     *    3. master referral
     *    4. layer 1 referral
     *    5. layer 2 referral
     *    6. seller
     */
    function getInitialDistributions(
        address _creator,
        address _buyer,
        uint256 _total
    ) external view returns (IDistribution.Initial memory) {
        require(_creator != address(0), "invalid creator address");
        require(_buyer != address(0), "invalid buyer address");
        require(_total > 0, "total value cannot be 0");

        (address master, uint256 level) = _getMaster(_buyer);
        InitialPayments memory payments = _calculateInitial(_total);
        address l1;
        address l2;

        // special cases if upline is master referral
        // case: level=0, msg.sender is the master
        // l1 & l2 = creator
        if (level == 0) {
            l1 = _creator;
            l2 = _creator;
        }
        // case: level=1, msg.sender's upline is master
        // l1 = master
        // l2 = creator
        if (level == 1) {
            l1 = master;
            l2 = _creator;
        }
        // case: level=2, msg.sender's upper upline is master
        // l2 = master
        if (level == 2) {
            l1 = referrals[_buyer];
            l2 = master;
        }
        // case: level > 2
        if (level > 2) {
            l1 = referrals[_buyer];
            l2 = referrals[l1];
        }

        return
            IDistribution.Initial(
                platformOwner(),
                payments.commissionPayment,
                _creator,
                payments.royaltyPayment,
                master,
                payments.masterPayment,
                l1,
                payments.referralL1Payment,
                l2,
                payments.referralL2Payment,
                _creator, // only creator receive the final amount
                payments.remaining
            );
    }

    /**
     * calculate distributions for KOL related addresses (initial sales)
     *
     * Addresses involved:
     *    1. platform owner
     *    2. creator
     *    3. master referral
     *    4. kol
     *    5. seller
     */
    function getKolDistributions(
        address _creator,
        address _buyer,
        uint256 _total
    ) external view returns (IDistribution.KOL memory) {
        require(_creator != address(0), "invalid creator address");
        require(_buyer != address(0), "invalid buyer address");
        require(_total > 0, "total value cannot be 0");

        (address master, uint256 level) = _getMaster(_buyer);
        require(level == 2, "unauthorized kol referral");

        KOLPayments memory payments = _calculateKOL(_total);

        return
            IDistribution.KOL(
                platformOwner(),
                payments.commissionPayment,
                _creator,
                payments.royaltyPayment,
                master,
                payments.masterPayment,
                referrals[_buyer],
                payments.kolPayment,
                _creator,
                payments.remaining
            );
    }

    function getMasters() external view returns (address[] memory) {
        return masters;
    }

    // check if address is in master addresses list
    function isMaster(address _addr) public view returns (bool) {
        if (_addr == address(0)) {
            return false;
        }

        bool master = false;
        for (uint256 i = 0; i < masters.length; i++) {
            if (masters[i] == _addr) {
                master = true;
                break;
            }
        }
        return master;
    }

    // check if address is already a member
    function isMember(address _addr) public view returns (bool) {
        if (_addr == address(0)) {
            return false;
        }

        bool member = false;
        for (uint256 i = 0; i < members.length; i++) {
            if (members[i] == _addr) {
                member = true;
                break;
            }
        }
        return member;
    }

    function _getMaster(address _currentUser)
        internal
        view
        returns (address, uint256)
    {
        address current = _currentUser;
        uint256 index = 0;
        while (!isMaster(current) && current != address(0)) {
            index = index + 1;
            current = referrals[current];
        }

        return (current, index);
    }

    function _calculateInitial(uint256 _total)
        internal
        view
        returns (InitialPayments memory)
    {
        uint256 commissionPayment = (_total * commissionTax) / 100;
        uint256 royaltyPayment = (_total * royaltyTax) / 100;
        uint256 masterPayment = (_total * referralTax_master) / 100;
        uint256 referralL1Payment = (_total * referralTax_l1) / 100;
        uint256 referralL2Payment = (_total * referralTax_l2) / 100;
        uint256 remaining = _total -
            commissionPayment -
            royaltyPayment -
            masterPayment -
            referralL1Payment -
            referralL2Payment;

        return
            InitialPayments(
                commissionPayment,
                royaltyPayment,
                masterPayment,
                referralL1Payment,
                referralL2Payment,
                remaining
            );
    }

    function _calculateKOL(uint256 _total)
        internal
        view
        returns (KOLPayments memory)
    {
        uint256 commissionPayment = (_total * commissionTax) / 100;
        uint256 royaltyPayment = (_total * royaltyTax) / 100;
        uint256 masterPayment = (_total * referralTax_master) / 100;
        uint256 kolPayment = (_total * referralTax_kol) / 100;
        uint256 remaining = _total -
            commissionPayment -
            royaltyPayment -
            masterPayment -
            kolPayment;

        return
            KOLPayments(
                commissionPayment,
                royaltyPayment,
                masterPayment,
                kolPayment,
                remaining
            );
    }
}