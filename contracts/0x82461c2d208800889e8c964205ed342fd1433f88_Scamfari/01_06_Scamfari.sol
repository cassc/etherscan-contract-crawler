// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Scamfari is OwnableUpgradeable {
    modifier onlyInvestigator() {
        require(investigators[_msgSender()], "Caller is not an investigator");
        _;
    }

    /// Initializes the contract
    function initialize() public initializer {
        __Ownable_init();
    }

    struct Configuration {
        address reward_token;
        uint256 reward_amount;
    }

    enum Network {
        NEAR,
        Aurora,
        Solana,
        Ethereum,
        BNBChain,
        Bitcoin,
        Polygon,
        OKTC,
        Tron,
        Linea,
        Arbitrum,
        Optimism,
        Avalanche,
        Cronos
    }

    enum Category {
        SocialMediaScammer,
        FraudulentWebsite,
        ScamProject,
        TerroristFinancing
    }

    enum ReportStatus {
        Pending,
        Accepted,
        Rejected,
        Claimed
    }

    struct Report {
        uint id;
        address reporter;
        Network network;
        Category category;
        string addr;
        string url;
        ReportStatus status;
        string reject_reason;
        string[] proof;
        string description;
    }

    enum ReporterStatus {
        None,
        Blocked,
        Active
    }

    struct Reporter {
        uint[] reports;
        uint256 reward;
        ReporterStatus status;
        string username;
        uint accepted_reports;
    }

    Configuration public configuration;
    mapping(address => bool) private investigators;
    mapping(uint => Report) private reports;
    uint public report_count;

    uint private constant TOP_REPORTER_COUNT = 10;
    struct TopReporter {
        address reporter;
        uint accepted_reports;
    }

    mapping(address => Reporter) private reporters;
    mapping(string => bool) private reported_address;

    event ConfigurationUpdated(address reward_token, uint256 reward_amount);

    /**
     * @param reward_token_ The address of the reward token contract
     * @param reward_amount_ The amount of reward tokens to give to reporters
     * @dev Throws if called by any account other than the contract owner
     */
    function updateConfiguration(
        address reward_token_,
        uint256 reward_amount_
    ) public onlyOwner {
        configuration.reward_token = reward_token_;
        configuration.reward_amount = reward_amount_;

        emit ConfigurationUpdated(reward_token_, reward_amount_);
    }

    event ReportCreated(uint indexed id, address reporter, string addr);

    /**
     * @param network_ The network (blockchain) of the report
     * @param category_ The category of the report
     * @param addr_ The address of the scammer
     * @param url_ The URL associated with the illicit activity
     * @param proof_ The proof of the illicit activity (e.g. links to screenshots)
     * @dev Throws if the reward token is not set
     * @dev Throws if the reward amount is not set
     * @dev Throws if the reporter is blocked
     */
    function createReport(
        Network network_,
        Category category_,
        string memory addr_,
        string memory url_,
        string[] memory proof_,
        string memory description_
    ) public {
        require(
            configuration.reward_token != address(0),
            "Reward token not set"
        );
        require(configuration.reward_amount > 0, "Reward amount not set");

        require(
            reporters[_msgSender()].status != ReporterStatus.Blocked,
            "Reporter is blocked"
        );

        require(!reported_address[addr_], "Address is already reported");

        // Increment report count
        report_count += 1;

        uint id = report_count;

        // Add report ID to reporter's list of reports
        reporters[_msgSender()].reports.push(report_count);

        // If reporter is new, set status to active
        if (reporters[_msgSender()].status == ReporterStatus.None) {
            reporters[_msgSender()].status = ReporterStatus.Active;
            reporters_count += 1;
        }

        // Add report record to list of reports
        reports[id] = Report({
            id: id,
            reporter: _msgSender(),
            network: network_,
            category: category_,
            addr: addr_,
            url: url_,
            status: ReportStatus.Pending,
            reject_reason: "",
            proof: proof_,
            description: description_
        });

        // Mark address as reported
        reported_address[addr_] = true;

        emit ReportCreated(id, _msgSender(), addr_);
    }

    event ReportAccepted(uint indexed id);

    /**
     * @param id_ The ID of the report to accept
     * @dev Throws if called by any account other than an investigator
     * @dev Throws if the report does not exist
     * @dev Throws if the report is not pending
     */
    function accept(uint id_) public onlyInvestigator {
        require(reports[id_].id == id_, "Report does not exist");
        require(
            reports[id_].status == ReportStatus.Pending,
            "Report is not pending"
        );

        // Set report status to Accepted
        reports[id_].status = ReportStatus.Accepted;

        // Get reward amount for the category, if category is not set, use default reward amount
        uint256 reward_amount = category_rewards[reports[id_].category];
        if (reward_amount == 0) {
            reward_amount = configuration.reward_amount;
        }

        // Add the reward amount to the reporter's balance
        reporters[reports[id_].reporter].reward += reward_amount;
        reporters[reports[id_].reporter].accepted_reports += 1;

        uint accepted_reports = reporters[reports[id_].reporter]
            .accepted_reports;

        updateTopReporters(reports[id_].reporter, accepted_reports);

        accepted_reports_count += 1;

        emit ReportAccepted(id_);
    }

    /**
     * @param reporter The address of the reporter that should be checked for the top list
     * @param accepted_reports The number of accepted reports of the reporter
     **/
    function updateTopReporters(
        address reporter,
        uint accepted_reports
    ) private {
        // Be the first to make the list
        if (top_reporters.length == 0) {
            top_reporters.push(
                TopReporter({
                    reporter: reporter,
                    accepted_reports: accepted_reports
                })
            );
            return;
        }

        // Check whether the reporter belongs to the list of top men
        uint threshold = top_reporters[top_reporters.length - 1]
            .accepted_reports;

        // The barrier of entry is zero if the list is not full yet
        if (top_reporters.length < TOP_REPORTER_COUNT) {
            threshold = 0;
        }

        if (accepted_reports > threshold) {
            // Update the new value of accepted reports for the reporter
            bool found = false;
            uint pos = 0;
            for (uint i = 0; i < top_reporters.length; i++) {
                pos = i;
                if (top_reporters[i].reporter == reporter) {
                    top_reporters[i].accepted_reports = accepted_reports;
                    found = true;
                    break;
                }
            }

            // It seems that our guy has pushed someone else off the chart
            if (!found) {
                // Another one bites the dust
                if (top_reporters.length == TOP_REPORTER_COUNT) {
                    top_reporters.pop();
                }

                // There's a new contender in town
                top_reporters.push(
                    TopReporter({
                        reporter: reporter,
                        accepted_reports: accepted_reports
                    })
                );
            }

            // Move the reporter up the chart until it reaches its rightful place
            for (uint i = pos; i > 0; i--) {
                if (
                    top_reporters[i].accepted_reports >
                    top_reporters[i - 1].accepted_reports
                ) {
                    TopReporter memory temp = top_reporters[i - 1];
                    top_reporters[i - 1] = top_reporters[i];
                    top_reporters[i] = temp;
                } else {
                    break;
                }
            }
        }
    }

    event ReportRejected(uint indexed id);

    /**
     * @param id_ The ID of the report to reject
     * @param reason The reason for rejecting the report
     * @dev Throws if called by any account other than an investigator
     * @dev Throws if the report does not exist
     * @dev Throws if the report is not pending
     */
    function reject(uint id_, string memory reason) public onlyInvestigator {
        require(reports[id_].id == id_, "Report does not exist");
        require(
            reports[id_].status == ReportStatus.Pending,
            "Report is not pending"
        );

        // Set report status to Rejected
        reports[id_].status = ReportStatus.Rejected;

        // Set reject reason
        reports[id_].reject_reason = reason;

        // Make address reportable again
        reported_address[reports[id_].addr] = false;

        emit ReportRejected(id_);
    }

    /**
     * @param id_ The ID of the report to get
     * @return report The report
     */
    function getReport(uint id_) public view returns (Report memory) {
        return reports[id_];
    }

    /**
     * @param addr_ The address of the reporter
     * @param skip The number of reports to skip
     * @param take The number of reports to take
     * @return result The list of reports
     */
    function getReportsByReporter(
        address addr_,
        uint skip,
        uint take
    ) public view returns (Report[] memory) {
        uint[] memory report_ids = reporters[addr_].reports;
        uint total_count = report_ids.length;

        if (total_count == 0) {
            return new Report[](0);
        }

        uint count = take;
        if (count > total_count - skip) {
            count = total_count - skip;
        }

        Report[] memory result = new Report[](count);

        for (uint i = 0; i < count; i++) {
            result[i] = reports[report_ids[skip + i]];
        }

        return result;
    }

    /**
     * @param skip The number of reports to skip
     * @param take The number of reports to take
     * @return result The list of reports
     */
    function getReports(
        uint skip,
        uint take
    ) public view returns (Report[] memory) {
        uint total_count = report_count;

        if (total_count == 0) {
            return new Report[](0);
        }

        uint count = take;
        if (count > total_count - skip) {
            count = total_count - skip;
        }

        Report[] memory result = new Report[](count);

        for (uint i = 0; i < count; i++) {
            result[i] = reports[skip + i + 1];
        }

        return result;
    }

    /**
     * @return status_ Reporter status
     * @return reward_ Reporter reward balance
     * @return report_count_ Number of reports submitted by the reporter
     * @return is_investigator_ Whether the reporter is an investigator
     * @return username_ Reporter username
     */
    function getMyStatus()
        public
        view
        returns (
            ReporterStatus status_,
            uint256 reward_,
            uint report_count_,
            bool is_investigator_,
            string memory username_
        )
    {
        Reporter memory reporter = reporters[_msgSender()];
        return (
            reporter.status,
            reporter.reward,
            reporter.reports.length,
            investigators[_msgSender()],
            reporter.username
        );
    }

    event RewardClaimed(address indexed reporter, uint256 amount);

    /**
     * @param amount_ The amount of reward tokens to claim
     * @dev Throws if the reporter does not have enough reward balance
     * @dev Throws if the transfer fails
     */
    function claim(uint256 amount_) public {
        require(
            reporters[_msgSender()].reward >= amount_,
            "Insufficient balance"
        );
        require(
            IERC20(configuration.reward_token).transfer(_msgSender(), amount_),
            "Transfer failed"
        );
        require(
            reporters[_msgSender()].status == ReporterStatus.Active,
            "Reporter is not active"
        );

        checkDailyLimit(amount_);

        reporters[_msgSender()].reward -= amount_;

        applyDailyLimit(amount_);

        emit RewardClaimed(_msgSender(), amount_);
    }

    event ReporterBlocked(address indexed reporter);

    /**
     * @param addr_ The address of the reporter to block
     * @dev Throws if called by any account other than the contract owner
     * @dev Throws if the reporter is not active
     */
    function blockReporter(address addr_) public onlyOwner {
        require(
            reporters[addr_].status == ReporterStatus.Active,
            "Reporter is not active"
        );

        reporters[addr_].status = ReporterStatus.Blocked;

        emit ReporterBlocked(addr_);
    }

    event ReporterUnblocked(address indexed reporter);

    /**
     * @param addr_ The address of the reporter to unblock
     * @dev Throws if called by any account other than the contract owner
     * @dev Throws if the reporter is not blocked
     */
    function unblockReporter(address addr_) public onlyOwner {
        require(
            reporters[addr_].status == ReporterStatus.Blocked,
            "Reporter is not blocked"
        );

        reporters[addr_].status = ReporterStatus.Active;

        emit ReporterUnblocked(addr_);
    }

    event InvestigatorAdded(address indexed investigator);

    /**
     * @param addr_ The address of the investigator to add
     */
    function addInvestigator(address addr_) public onlyOwner {
        require(!investigators[addr_], "Account is already an investigator");

        investigators[addr_] = true;

        emit InvestigatorAdded(addr_);
    }

    event InvestigatorRemoved(address indexed investigator);

    /**
     * @param addr_ The address of the investigator to remove
     */
    function removeInvestigator(address addr_) public onlyOwner {
        require(investigators[addr_], "Account is not an investigator");

        investigators[addr_] = false;

        emit InvestigatorRemoved(addr_);
    }

    /**
     * @param addr_ The address to check
     * @return result Whether the address is already reported
     */
    function checkAddress(string memory addr_) public view returns (bool) {
        return reported_address[addr_];
    }

    event ReporterProfileUpdated(address indexed reporter, string username);

    /**
     * @param username_ The username to set
     */
    function setReporterProfile(string memory username_) public {
        require(
            reporters[_msgSender()].status != ReporterStatus.Blocked,
            "Reporter is blocked"
        );

        // If reporter is new, set status to active
        if (reporters[_msgSender()].status == ReporterStatus.None) {
            reporters[_msgSender()].status = ReporterStatus.Active;
        }

        reporters[_msgSender()].username = username_;

        emit ReporterProfileUpdated(_msgSender(), username_);
    }

    struct TopReporterRecord {
        address addr;
        string username;
        uint score;
    }
    TopReporter[] private top_reporters;

    /**
     * @return result The list of top reporters
     */
    function getTopReporters()
        public
        view
        returns (TopReporterRecord[] memory)
    {
        uint count = top_reporters.length;

        if (count == 0) {
            return new TopReporterRecord[](0);
        }

        TopReporterRecord[] memory result = new TopReporterRecord[](count);

        for (uint i = 0; i < count; i++) {
            result[i] = TopReporterRecord({
                addr: top_reporters[i].reporter,
                username: reporters[top_reporters[i].reporter].username,
                score: top_reporters[i].accepted_reports
            });
        }

        return result;
    }

    uint public reporters_count;
    uint public accepted_reports_count;

    /**
     * @return result The last 10 reports
     */
    function getLastReports() public view returns (Report[] memory) {
        uint count = 10;

        if (report_count == 0) {
            return new Report[](0);
        }

        if (report_count < 10) {
            count = report_count;
        }

        Report[] memory result = new Report[](count);

        for (uint i = 0; i < count; i++) {
            result[i] = reports[report_count - i];
        }

        return result;
    }

    mapping(Category => uint256) public category_rewards;

    /**
     * @param category_ The category to get the reward for
     * @param reward_amount_ The reward amount
     * @dev Throws if called by any account other than the contract owner
     */
    function setCategoryReward(
        Category category_,
        uint256 reward_amount_
    ) public onlyOwner {
        category_rewards[category_] = reward_amount_;
    }

    uint256 private _daily_claim_limit; // 0 = no limit

    struct DailyClaim {
        uint256 claimed_today; // amount claimed today
        uint256 today_started; // timestamp of "today's" start
    }

    mapping(address => DailyClaim) private _daily_claims;

    event DailyClaimLimitUpdated(uint256 daily_claim_limit_);

    /**
     * @param daily_claim_limit The daily claim limit
     * @dev Throws if called by any account other than the contract owner
     */
    function setDailyClaimLimit(uint256 daily_claim_limit) public onlyOwner {
        _daily_claim_limit = daily_claim_limit;
        emit DailyClaimLimitUpdated(daily_claim_limit);
    }

    /**
     * @return claimed_today The amount of tokens that were claimed today
     * @return today_started The timestamp of the today's start
     * @return daily_limit The daily claim limit
     */
    function getMyDailyLimit()
        public
        view
        returns (uint256 claimed_today, uint today_started, uint256 daily_limit)
    {
        DailyClaim storage daily_claim = _daily_claims[_msgSender()];
        if (block.timestamp - daily_claim.today_started > 24 hours) {
            // Reset daily claim amount if the timestamp has expired
            return (0, 0, _daily_claim_limit);
        } else {
            return (
                daily_claim.claimed_today,
                daily_claim.today_started,
                _daily_claim_limit
            );
        }
    }

    /**
     * @param amount_ The amount of tokens to check
     * @dev Throws if the amount exceeds the daily claim limit
     */
    function checkDailyLimit(uint256 amount_) internal {
        if (_daily_claim_limit == 0) {
            return;
        }

        (uint256 claimed_today, , ) = getMyDailyLimit();
        require(
            claimed_today + amount_ <= _daily_claim_limit,
            "Daily limit exceeded"
        );

        DailyClaim storage daily_claim = _daily_claims[_msgSender()];
        if (block.timestamp - daily_claim.today_started > 24 hours) {
            daily_claim.today_started = block.timestamp;
            daily_claim.claimed_today = 0;
        }
    }

    /**
     * @param amount_ The amount of tokens to apply
     * @dev Applies the daily claim limit
     */
    function applyDailyLimit(uint256 amount_) internal {
        if (_daily_claim_limit == 0) {
            return;
        }

        DailyClaim storage daily_claim = _daily_claims[_msgSender()];
        daily_claim.today_started = block.timestamp;
        if (daily_claim.claimed_today == 0) {
            daily_claim.claimed_today = amount_;
        } else {
            daily_claim.claimed_today += amount_;
        }
    }
}