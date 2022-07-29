//SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "erc721a/contracts/ERC721A.sol";
import "./SalesActivation.sol";
import "./OneShos1155Interface.sol";

// ................................................................................................................................
// ...............,................................................................................................................
// ............:;+++;:,............................................................................................................
// ............,,:;+++++;:,,........................................................,;.............................................
// ................,,:;+++++;::,....................................................:+.............................................
// ....................,,:;++++++;;:,,..............................................:+,............................................
// .........................,:;;++++++;;:,,.........................................++:............................................
// .............................,,:;;+++++++;;::,,.................................;+++,...........................................
// ..................................,,::;+++++++++;;::,,,,......................,;+++++:,.........................................
// ........................................,,::;;+++++++++++;;;;:::::,,,,,,,:::;;+++++++++;:,,.....................................
// ...............................................,,::;;++++++++++++++++++++++++++++++++++++++++;;::::,,,,,........................
// ......................................................,,:::;;++++++++++++++++++++++++++++++++++++++++++++++;;;;;;::,............
// ..............................................................,,,,::;;++++++++++++++++++++++++++;;;;:::::,,,,,,,,,,.............
// .......................................................................,,,:;++++++++++++;::,,,..................................
// .............................................................................,:++++++;,.........................................
// ...............................................................................,;+++:...........................................
// ................................................................................,+++............................................
// .................................................................................;+;............................................
// .................................................................................:+:............................................
// .................................................................................:+,............................................
// .................................................................................:+,............................................
// ..................................................................................,.............................................
// .......................,,,,,,,,,,,,,,,,,,,,,,,,,..........................,,,..........,,,,,,,,,,,,,,,,,,,,,,,,,................
// ..............,*SS+.:[email protected]@@@@@@@@@@@@@@@@@@@@@@@#S*,.+SS%......,SSS:..:*%S##@##S?;...:[email protected]@@@@@@@@@@@@@@@@@@@@@@@#S*,.............
// ............:%#@@@*,@@@%++;;;;;;;;;;;;;;;;;;;+*#@@%.*@@#......,@@@;[email protected]@@@S%%S#@@@S,,@@@%++;;;;;;;;;;;;;;;;;;;+*#@@%.............
// ............;[email protected]@@*,#@@S?**********************?*+:.*@@#*******@@@:;@@@*,....,;@@@?,@@@S?**********************?*+:.............
// [email protected]@*.:?S#@@@@@@@@@@@@@@@@@@@@@@@@@@%,*@@@@@@@@@@@@@:*@@#........%@@S.:?S#@@@@@@@@@@@@@@@@@@@@@@@@@@%,............
// [email protected]@+:%%%;,,,,,,,,,,,,,,,,,,,,,,,*@@@:[email protected]@#::::::;@@@:;@@@?,....,[email protected]@@?:%%%;,,,,,,,,,,,,,,,,,,,,,,,*@@@;............
// [email protected]@*,[email protected]@@S%%%%%%%%%%%%%%%%%%%%%S#@@S,*@@#......,@@@;[email protected]@@@#SSS#@@@%,,[email protected]@@S%%%%%%%%%%%%%%%%%%%%%S#@@S,............
// ...............ESS+..;*%SSSSSSSSSSSSSSSSSSSSSSS%?+,.+SS%......,SSS:..:*%S####S%*;....;*%SSSSSSSSSSSSSSSSSSSSSSS%?+,.............
// ..........................................................................,,....................................................

error OneShos__NoBalanceOf1155();
error OneShos__NotEnoughBalance();
error OneShos__1155NotApproved();

contract OneShos is ERC721A, SalesActivation {
    /* State Variable */

    string private s_baseTokenURI;
    uint256 private s_presale_price = 0.05 ether;
    uint256 private s_price = 0.06 ether;
    address private s_oneShos1155ContractAddress;
    uint64 private s_token_id = 0;
    uint256 private s_max_one_shos_total = 6600;
    uint256 private s_max_one_shos = 4423;
    uint256 private s_max_per_wallet = 2;
    uint256 private s_max_per_transaction = 5;
    uint256 private s_presale_period_purchased;
    uint256 private s_presale_period_phase_max;
    uint256 private s_team_allocated;
    uint256 private s_total_purchased;
    mapping(address => bool) private s_presale_list;
    mapping(address => uint256) private s_presale_list_bought;
    // team addresses
    address private s_one_shos_wallet;
    address private immutable i_commission;

    /* Functions */

    constructor(
        uint256 publicSalesStartTime,
        uint256 preSalesStartTime,
        uint256 preSalesEndTime,
        uint256 claimStartTime,
        address oneShos1155ContractAddress,
        uint256 team_allocated,
        uint256 presale_period_phase_max,
        address one_shos_wallet,
        string memory baseTokenURI,
        address commission
    )
        ERC721A("1Shos", "1SHOS")
        SalesActivation(publicSalesStartTime, preSalesStartTime, preSalesEndTime, claimStartTime)
    {
        s_oneShos1155ContractAddress = oneShos1155ContractAddress;
        s_team_allocated = team_allocated;
        s_presale_period_phase_max = presale_period_phase_max;
        s_one_shos_wallet = one_shos_wallet;
        s_baseTokenURI = baseTokenURI;
        i_commission = commission;
    }

    /**
     * @dev claim the erc721 token for user that approved this contract
     */
    function claimFrom1155(uint256 numberToClaim) external isClaimActive {
        OneShos1155Interface oneShos1155contract = OneShos1155Interface(s_oneShos1155ContractAddress);
        // Check if is approved
        if (!oneShos1155contract.isApprovedForAll(msg.sender, address(this))) {
            revert OneShos__1155NotApproved();
        }
        uint256 oneShos1155Balance = oneShos1155contract.balanceOf(msg.sender, s_token_id);
        // Check if has 1155 balance
        if (oneShos1155Balance < 1) {
            revert OneShos__NoBalanceOf1155();
        }
        if (oneShos1155Balance < numberToClaim) {
            revert OneShos__NotEnoughBalance();
        }
        oneShos1155contract.burn(msg.sender, s_token_id, numberToClaim);
        _safeMint(msg.sender, numberToClaim);
    }

    /**
     * @dev Presale
     */
    function presales(uint256 oneshosNumber) external payable isPreSalesActive {
        uint256 supply = totalSupply();
        require(s_presale_list[msg.sender], "You are not on the presale list");
        require(
            s_presale_period_purchased + oneshosNumber <= s_presale_period_phase_max,
            "Purchase exceeds max allowed"
        );
        require(msg.value >= s_presale_price * oneshosNumber, "Ether sent is not correct");
        require(s_presale_list_bought[msg.sender] + oneshosNumber <= s_max_per_wallet, "Purchase exceeds max allowed");
        require(tx.origin == msg.sender, "Contracts not allowed to mint");
        require(supply + oneshosNumber <= s_max_one_shos_total, "Exceeds maximum one shos supply");

        s_presale_list_bought[msg.sender] += oneshosNumber;
        s_presale_period_purchased += oneshosNumber;
        s_total_purchased += oneshosNumber;
        _safeMint(msg.sender, oneshosNumber);
    }

    /**
     * @dev Mint One Shos
     */
    function mint(uint256 oneShosNumber) external payable isPublicSalesActive {
        uint256 supply = totalSupply();
        require(msg.value >= s_price * oneShosNumber, "Ether sent is not correct");
        require(
            s_total_purchased + oneShosNumber <= s_max_one_shos - s_team_allocated,
            "Exceeds public sale one shos supply"
        );
        require(oneShosNumber > 0, "You cannot mint 0 one shos.");
        require(oneShosNumber <= s_max_per_transaction, "You are not allowed to buy this many one shos at once.");
        require(tx.origin == msg.sender, "Contracts not allowed");
        require(supply + oneShosNumber <= s_max_one_shos_total, "Exceeds maximum one shos supply");

        s_total_purchased += oneShosNumber;
        _safeMint(msg.sender, oneShosNumber);
    }

    /**
     * @dev Owner Mint OneShos
     */
    function ownerMint(address _to, uint256 oneShosNumber) external onlyOwner {
        uint256 supply = totalSupply();
        require(supply + oneShosNumber <= s_max_one_shos_total, "Exceeds maximum one shos supply");

        _safeMint(_to, oneShosNumber);
    }

    /**
     * @dev Change the base URI when we move IPFS (Callable by owner only)
     */
    function setBaseURI(string memory _uri) public onlyOwner {
        s_baseTokenURI = _uri;
    }

    /**
     * @dev Change the max team mint
     */
    function setTeamMint(uint256 teamMax) public onlyOwner {
        s_team_allocated = teamMax;
    }

    /**
     * @dev Change the Pre Sales Max
     */
    function setPreSalesMax(uint256 presaleMax) public onlyOwner {
        s_presale_period_phase_max = presaleMax;
    }

    /**
     * @dev Change the presale purchased number
     */
    function setPreSalesPurchased(uint256 presalePurchased) public onlyOwner {
        s_presale_period_purchased = presalePurchased;
    }

    /**
     * @dev Change the total Sales one shos
     */
    function setTotalSalesOneShos(uint256 totalOneShos) public onlyOwner {
        s_max_one_shos = totalOneShos;
    }

    /**
     * @dev Change the total one shos
     */
    function setMaxTotalSalesOneShos(uint256 totalOneShos) public onlyOwner {
        s_max_one_shos_total = totalOneShos;
    }

    /**
     * @dev Change the presale list max number
     */
    function setMaxPerWallet(uint256 _max_per_wallet) public onlyOwner {
        s_max_per_wallet = _max_per_wallet;
    }

    /**
     * @dev Change the public sale max per transaction
     */
    function setMaxPerTransaction(uint256 _max_per_transaction) public onlyOwner {
        s_max_per_transaction = _max_per_transaction;
    }

    /**
     * @dev Add people to Presale List
     */
    function addToPresaleList(address[] calldata _presale_list) public onlyOwner {
        for (uint256 i = 0; i < _presale_list.length; i++) {
            s_presale_list[_presale_list[i]] = true;
            s_presale_list_bought[_presale_list[i]] > 0 ? s_presale_list_bought[_presale_list[i]] : 0;
        }
    }

    /**
     * @dev Remove people from Presale List
     */
    function removeFromPresaleList(address[] calldata removeList) public onlyOwner {
        for (uint256 i = 0; i < removeList.length; i++) {
            s_presale_list[removeList[i]] = false;
            s_presale_list_bought[removeList[i]] = 0;
        }
    }

    /**
     * @dev Set Price of Presale if need (Callable by owner only)
     */
    function setPresalePrice(uint256 _newPrice) public onlyOwner {
        s_presale_price = _newPrice;
    }

    /**
     * @dev Set Price if need (Callable by owner only)
     */
    function setPrice(uint256 _newPrice) public onlyOwner {
        s_price = _newPrice;
    }

    /**
     * @dev Set Team wallet
     */
    function setTeamWallet(address _newWallet) public onlyOwner {
        s_one_shos_wallet = _newWallet;
    }

    /**
     * @dev Set 1155 contract address
     */
    function setOneshos1155ContractAddress(address _newAddress) public onlyOwner {
        s_oneShos1155ContractAddress = _newAddress;
    }

    /**
     * @dev Set Token Id of 1155 Contreact
     */
    function setTokenIdOf1155Contract(uint64 _newTokenId) public onlyOwner {
        s_token_id = _newTokenId;
    }

    /**
     * @dev Withdraw ETH from this contract (Callable by owner only)
     */
    function withdraw() public onlyOwner {
        uint256 _balance = address(this).balance;
        require(payable(i_commission).send((_balance * 5) / 100));
        require(payable(s_one_shos_wallet).send((_balance * 95) / 100));
    }

    /* View / Pure Functions */

    function getOneshos1155ContractAddress() external view returns (address) {
        return s_oneShos1155ContractAddress;
    }

    function getTokenIdOf1155Contract() external view returns (uint64) {
        return s_token_id;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return s_baseTokenURI;
    }

    function getPresalePrice() external view returns (uint256) {
        return s_presale_price;
    }

    function getPrice() external view returns (uint256) {
        return s_price;
    }

    function getMaxOneShos() external view returns (uint256) {
        return s_max_one_shos;
    }

    function getMaxTotalOneShos() external view returns (uint256) {
        return s_max_one_shos_total;
    }

    function getMaxPerWallet() external view returns (uint256) {
        return s_max_per_wallet;
    }

    function getMaxPerTransaction() external view returns (uint256) {
        return s_max_per_transaction;
    }

    function getPresalePeriodPurchased() external view returns (uint256) {
        return s_presale_period_purchased;
    }

    function getPresalePeriodPhaseMax() external view returns (uint256) {
        return s_presale_period_phase_max;
    }

    function isAllMinted() external view returns (bool) {
        return (s_max_one_shos - s_total_purchased - s_team_allocated) < 1;
    }

    function getTotalPurchased() external view returns (uint256) {
        return s_total_purchased;
    }

    function isWalletInPresaleList(address wallet) external view returns (bool) {
        return s_presale_list[wallet];
    }

    function presaleBought(address wallet) external view returns (uint256) {
        return s_presale_list_bought[wallet];
    }
}