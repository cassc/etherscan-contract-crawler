// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

/***
 *
 *
 *    8 888888888o   8 8888                  .8.           8888888888',8888'  8 8888 b.             8     ,o888888o.
 *    8 8888    `88. 8 8888                 .888.                 ,8',8888'   8 8888 888o.          8    8888     `88.
 *    8 8888     `88 8 8888                :88888.               ,8',8888'    8 8888 Y88888o.       8 ,8 8888       `8.
 *    8 8888     ,88 8 8888               . `88888.             ,8',8888'     8 8888 .`Y888888o.    8 88 8888
 *    8 8888.   ,88' 8 8888              .8. `88888.           ,8',8888'      8 8888 8o. `Y888888o. 8 88 8888
 *    8 8888888888   8 8888             .8`8. `88888.         ,8',8888'       8 8888 8`Y8o. `Y88888o8 88 8888
 *    8 8888    `88. 8 8888            .8' `8. `88888.       ,8',8888'        8 8888 8   `Y8o. `Y8888 88 8888   8888888
 *    8 8888      88 8 8888           .8'   `8. `88888.     ,8',8888'         8 8888 8      `Y8o. `Y8 `8 8888       .8'
 *    8 8888    ,88' 8 8888          .888888888. `88888.   ,8',8888'          8 8888 8         `Y8o.`    8888     ,88'
 *    8 888888888P   8 888888888888 .8'       `8. `88888. ,8',8888888888888   8 8888 8            `Yo     `8888888P'
 *                                                        .         .
 *    `8.`888b                 ,8'  ,o888888o.           ,8.       ,8.          8 8888888888   b.             8
 *     `8.`888b               ,8'. 8888     `88.        ,888.     ,888.         8 8888         888o.          8
 *      `8.`888b             ,8',8 8888       `8b      .`8888.   .`8888.        8 8888         Y88888o.       8
 *       `8.`888b     .b    ,8' 88 8888        `8b    ,8.`8888. ,8.`8888.       8 8888         .`Y888888o.    8
 *        `8.`888b    88b  ,8'  88 8888         88   ,8'8.`8888,8^8.`8888.      8 888888888888 8o. `Y888888o. 8
 *         `8.`888b .`888b,8'   88 8888         88  ,8' `8.`8888' `8.`8888.     8 8888         8`Y8o. `Y88888o8
 *          `8.`888b8.`8888'    88 8888        ,8P ,8'   `8.`88'   `8.`8888.    8 8888         8   `Y8o. `Y8888
 *           `8.`888`8.`88'     `8 8888       ,8P ,8'     `8.`'     `8.`8888.   8 8888         8      `Y8o. `Y8
 *            `8.`8' `8,`'       ` 8888     ,88' ,8'       `8        `8.`8888.  8 8888         8         `Y8o.`
 *             `8.`   `8'           `8888888P'  ,8'         `         `8.`8888. 8 888888888888 8            `Yo
 *
 *                                          ....
 *                                      .:-======:-=-:
 *                                    :-====+**+==*+==-
 *                                   -=============++===.
 *                                  :=====++********++===.
 *                                  ===+*####********====-
 *                                 :+++##*####*#####*+===-
 *                             ::  =********#*##*####*===.
 *                             -=-==#*********#**#*#*+==-
 *                              .:-=+#****#####*******==:
 *                                -==***#######****##*==-   .
 *                                ===****#######****+=====--.
 *                                ====*#********#*====:...
 *                                ====+#########======
 *                                ====+***#####*=-===-   -.
 *                              .-====*******##*======-::=:
 *                           .:-======*********#*+====++++:.
 *                              :--==+************##*#*******=.
 *                                :+*#*******##*####**********#=
 *                           .-=+*##**####**#*******************
 *                        -+***********************************+
 *                      :*******************************##****#+
 *                     :*******************************##*****#-
 *                      ******#************#**+++====++********:
 *                      :****#*************==:---::----+*******
 *                       -****---:-=-==++=--:---:--::-=+*******
 *                        =*#=------:--:-------:---:---#*****+=
 *                         +*::::::-:--::---::--::-----#****+*:
 *                          +-:--:-----------=-===-=--=#****+*
 *                           =+------:-:----::--:----:=#****+=
 *                            -**-------::---:-:-::---+#****#-
 *                             .*=::::-::---:---:-:=++*#****#.
 *                               ========++++**********##**#*
 *                                ==++=++=+==-==-:::--=##**#-
 *                                ::::-::--:-::--:-::--*#**#.
 *                               .:-:::::::::::::::::::-#*##=
 *                              .-:--:::-:-:-:::::::::--=#*#*
 *                             .----::::-::-::::::-:::--=***#:
 *                             -:-:::-:-:--:-:::::::----=+#*#+
 *                            ::-::::::-----:-::::-::---==****
 *                           .:-:--::--::::---:::--:::---==**#
 *                           -::-:::-:::-:-----:-:-::-:=--=**#
 *                          .:::::-::::::---:::::::-:::-=-=+*#
 *                          ::::--::::----::-::::--:::-=-:==*#.
 *                          :::-:::::::::::::-::::-----=:-==*#.
 *                          ::-::::::::::---:--------:-=-=-=*#.
 *                          -:::::::::::::::--------=::---=+*#.
 *                          :::::::---:--------:-----:-==--+*#:
 *                          ::---------:::-----::::-=:---==#*#-
 *                          .----:-:::::--:-:-::--::-:=---+###+
 *                           :-------:::::---::--:--:=-=--*####+
 *                           :-:--:--:--:-----=--=-:=--=-:+#***#*-
 *                           .:--=-:=-:-------=-::-=--=-:. #*****#=
 *                            ::----:-=:----=---:---:=--:. **##*##*.
 *                            :::-::=:-------=--:-----:::  =**#*###=
 *                            .-::--------:--:---:-:--::.   *+ +*##.
 *                             :-:::---:::-::----:-:--.:.    = .+**
 *                             .:::--::::::------:------       ...+=
 ************************************************************************************
 ************************************************************************************
 ************************************************************************************
 * PROJECT: @PowerOfWomenNFT
 * FOUNDER: @leahsams & @PowerOfJack
 * ART: @leahsams
 * DEV: @ghooost0x2a
 **********************************
 * @title: Blazing Women
 * @author: @ghooost0x2a
 **********************************
 * ERC721B2FA - Ultra Low Gas - 2 Factor Authentication
 *****************************************************************
 * ERC721B2FA is based on ERC721B low gas contract by @squuebo_nft
 * and the LockRegistry/Guardian contracts by @OwlOfMoistness
 *****************************************************************
 */

import "./ERC721B2FAEnumLitePausable.sol";
import "./GuardianLiteB2FA.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract BlazingWomen is ERC721B2FAEnumLitePausable, GuardianLiteB2FA {
    using MerkleProof for bytes32[];
    using Address for address;
    using Strings for uint256;

    event Withdrawn(address indexed payee, uint256 weiAmount);

    uint256 public MAX_SUPPLY = 2500;

    address public POWERPASS_CONTRACT =
        0xD3eBa4755429934F9ACF73B7d3bC82115446dfE5;

    /**
     * Phase 0: Mint Disabled
     * Phase 1+: For PowerPass Holders
     * Phase 2+: For Power List
     * Phase 3+: Public
     */
    uint256 public mintPhase = 0;

    struct PhaseConfig {
        uint256 max_mints_per;
        uint256 price_per;
        uint256 price_per_fiveplus;
        uint256 price_per_tenplus;
    }

    PhaseConfig public powerPassHolderPhaseOneConf =
        PhaseConfig({
            max_mints_per: 10,
            price_per: 0.04 ether,
            price_per_fiveplus: 0.038 ether,
            price_per_tenplus: 0.036 ether
        });

    PhaseConfig public powerListPhaseTwoConf =
        PhaseConfig({
            max_mints_per: 10,
            price_per: 0.06 ether,
            price_per_fiveplus: 0.057 ether,
            price_per_tenplus: 0.054 ether
        });

    PhaseConfig public publicPhaseThreeConf =
        PhaseConfig({
            max_mints_per: 4242,
            price_per: 0.08 ether,
            price_per_fiveplus: 0.076 ether,
            price_per_tenplus: 0.072 ether
        });

    string internal baseURI = "";
    string internal uriSuffix = "";

    address public paymentRecipient =
        0xA94F799A34887582987eC8C050f080e252B70A21;

    bytes32 private merkleRoot = 0;
    mapping(address => uint256) public powerPassHolderMints;
    mapping(address => uint256) public powerlistMints;
    mapping(address => uint256) public publicMints;

    constructor() ERC721B2FAEnumLitePausable("BlazingWomen", "BW", 1) {}

    fallback() external payable {}

    receive() external payable {}

    function setPowerPassHolderPhaseOneConf(
        uint256 maxMintsPer,
        uint256 pricePer,
        uint256 pricePerFivePlus,
        uint256 pricePerTenPlus
    ) external onlyDelegates {
        powerPassHolderPhaseOneConf.max_mints_per = maxMintsPer;
        powerPassHolderPhaseOneConf.price_per = pricePer;
        powerPassHolderPhaseOneConf.price_per_fiveplus = pricePerFivePlus;
        powerPassHolderPhaseOneConf.price_per_tenplus = pricePerTenPlus;
    }

    function setPowerListPhaseTwoConf(
        uint256 maxMintsPer,
        uint256 pricePer,
        uint256 pricePerFivePlus,
        uint256 pricePerTenPlus
    ) external onlyDelegates {
        powerListPhaseTwoConf.max_mints_per = maxMintsPer;
        powerListPhaseTwoConf.price_per = pricePer;
        powerListPhaseTwoConf.price_per_fiveplus = pricePerFivePlus;
        powerListPhaseTwoConf.price_per_tenplus = pricePerTenPlus;
    }

    function setPublicPhaseThreeConf(
        uint256 maxMintsPer,
        uint256 pricePer,
        uint256 pricePerFivePlus,
        uint256 pricePerTenPlus
    ) external onlyDelegates {
        publicPhaseThreeConf.max_mints_per = maxMintsPer;
        publicPhaseThreeConf.price_per = pricePer;
        publicPhaseThreeConf.price_per_fiveplus = pricePerFivePlus;
        publicPhaseThreeConf.price_per_tenplus = pricePerTenPlus;
    }

    function setMintPhase(uint256 newPhase) external onlyDelegates {
        mintPhase = newPhase;
    }

    function tokenURI(uint256 tokenId)
        external
        view
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        return
            bytes(baseURI).length > 0
                ? string(
                    abi.encodePacked(baseURI, tokenId.toString(), uriSuffix)
                )
                : "";
    }

    function updatePowerPassContractAddress(address new_addy)
        external
        onlyDelegates
    {
        POWERPASS_CONTRACT = new_addy;
    }

    function getPowerPassBalance(address addy) public view returns (uint256) {
        return IERC721(POWERPASS_CONTRACT).balanceOf(addy);
    }

    function getMerkleRoot() public view onlyDelegates returns (bytes32) {
        return merkleRoot;
    }

    function setMerkleRoot(bytes32 mRoot) external onlyDelegates {
        merkleRoot = mRoot;
    }

    function updateBlackListedApprovals(
        address[] calldata addys,
        bool[] calldata blacklisted
    ) external onlyDelegates {
        require(
            addys.length == blacklisted.length,
            "Nb addys doesn't match nb bools."
        );
        for (uint256 i; i < addys.length; ++i) {
            _updateBlackListedApprovals(addys[i], blacklisted[i]);
        }
    }

    function isvalidMerkleProof(bytes32[] memory proof)
        public
        view
        returns (bool)
    {
        if (merkleRoot == 0) {
            return false;
        }
        bool proof_valid = proof.verify(
            merkleRoot,
            keccak256(abi.encodePacked(msg.sender))
        );
        return proof_valid;
    }

    function setBaseSuffixURI(
        string calldata newBaseURI,
        string calldata newURISuffix
    ) external onlyDelegates {
        baseURI = newBaseURI;
        uriSuffix = newURISuffix;
    }

    function setPaymentRecipient(address addy) external onlyDelegates {
        paymentRecipient = addy;
    }

    function setReducedMaxSupply(uint256 new_max_supply)
        external
        onlyDelegates
    {
        require(new_max_supply < MAX_SUPPLY, "Can only set a lower size.");
        require(
            new_max_supply >= totalSupply(),
            "New supply lower than current totalSupply"
        );
        MAX_SUPPLY = new_max_supply;
    }

    // Mint fns
    function freeTeamMints(uint256 quantity, address[] memory recipients)
        external
        onlyDelegates
    {
        if (recipients.length == 1) {
            for (uint256 i = 0; i < quantity; i++) {
                _minty(1, recipients[0]);
            }
        } else {
            require(
                quantity == recipients.length,
                "Number of recipients doesn't match quantity."
            );
            for (uint256 i = 0; i < recipients.length; i++) {
                _minty(1, recipients[i]);
            }
        }
    }

    function getTotalMintPrice(uint256 quantity, uint256 mintingPhase)
        public
        view
        returns (uint256)
    {
        uint256 totalPrice = 1 ether;

        if (quantity < 5) {
            if (mintingPhase == 1) {
                totalPrice = quantity * powerPassHolderPhaseOneConf.price_per;
            } else if (mintingPhase == 2) {
                totalPrice = quantity * powerListPhaseTwoConf.price_per;
            } else {
                totalPrice = quantity * publicPhaseThreeConf.price_per;
            }
        } else if (quantity >= 5 && quantity < 10) {
            if (mintingPhase == 1) {
                totalPrice =
                    quantity *
                    powerPassHolderPhaseOneConf.price_per_fiveplus;
            } else if (mintingPhase == 2) {
                totalPrice =
                    quantity *
                    powerListPhaseTwoConf.price_per_fiveplus;
            } else {
                totalPrice = quantity * publicPhaseThreeConf.price_per_fiveplus;
            }
        } else if (quantity >= 10) {
            if (mintingPhase == 1) {
                totalPrice =
                    quantity *
                    powerPassHolderPhaseOneConf.price_per_tenplus;
            } else if (mintingPhase == 2) {
                totalPrice = quantity * powerListPhaseTwoConf.price_per_tenplus;
            } else {
                totalPrice = quantity * publicPhaseThreeConf.price_per_tenplus;
            }
        }

        return totalPrice;
    }

    function powerPassMint(uint256 quantity) external payable {
        require(
            mintPhase >= 1 || _isDelegate(_msgSender()),
            "Power Pass Mint not open yet."
        );
        uint256 powerPassBalance = getPowerPassBalance(_msgSender());
        require(
            powerPassBalance > 0,
            "There are no Power Passes in your wallet!"
        );
        uint256 maxAllowedToMint = (powerPassBalance *
            powerPassHolderPhaseOneConf.max_mints_per) -
            powerPassHolderMints[_msgSender()];
        require(quantity <= maxAllowedToMint, "You cannot mint that many!");

        uint256 totalPrice = getTotalMintPrice(quantity, 1);

        require(msg.value == totalPrice, "Wrong amount of ETH sent!");

        powerPassHolderMints[_msgSender()] += quantity;
        _minty(quantity, _msgSender());
    }

    // Pre-sale mint
    function powerListMint(uint256 quantity, bytes32[] memory proof)
        external
        payable
    {
        require(
            mintPhase >= 2 || _isDelegate(_msgSender()),
            "Powerlist mint not open yet!"
        );
        uint256 maxAllowedToMint = powerListPhaseTwoConf.max_mints_per -
            powerlistMints[_msgSender()];
        require(quantity <= maxAllowedToMint, "You cannot mint that many!");

        uint256 totalPrice = getTotalMintPrice(quantity, 2);

        require(msg.value == totalPrice, "Wrong amount of ETH sent!");
        require(
            isvalidMerkleProof(proof),
            "You are not authorized for pre-sale."
        );

        powerlistMints[_msgSender()] += quantity;
        _minty(quantity, _msgSender());
    }

    // Public Mint
    function publicMint(uint256 quantity) external payable {
        require(
            mintPhase >= 3 || _isDelegate(_msgSender()),
            "Public mint not open yet!"
        );
        uint256 totalPrice = getTotalMintPrice(quantity, 3);

        require(msg.value == totalPrice, "Wrong amount of ETH sent!");

        if (publicPhaseThreeConf.max_mints_per != 4242) {
            uint256 maxAllowedToMint = publicPhaseThreeConf.max_mints_per -
                publicMints[_msgSender()];
            require(quantity <= maxAllowedToMint, "You cannot mint that many!");
            publicMints[_msgSender()] += quantity;
        }
        _minty(quantity, _msgSender());
    }

    function _minty(uint256 quantity, address addy) internal {
        require(quantity > 0, "Can't mint 0 tokens!");
        require(quantity + totalSupply() <= MAX_SUPPLY, "Max supply reached!");
        for (uint256 i = 0; i < quantity; i++) {
            _safeMint(addy, next());
        }
    }

    //Just in case some ETH ends up in the contract so it doesn't remain stuck.
    function withdraw() external onlyDelegates {
        uint256 contract_balance = address(this).balance;

        address payable w_addy = payable(paymentRecipient);

        (bool success, ) = w_addy.call{value: (contract_balance)}("");
        require(success, "Withdrawal failed!");

        emit Withdrawn(w_addy, contract_balance);
    }
}