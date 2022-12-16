// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/*
 ______     ______   ______     ______     ______        ______     __         ______     ______     ______     ______     _____    
/\  ___\   /\__  _\ /\  __ \   /\  ___\   /\  ___\      /\  ___\   /\ \       /\  ___\   /\  __ \   /\  == \   /\  ___\   /\  __-.  
\ \___  \  \/_/\ \/ \ \  __ \  \ \ \__ \  \ \  __\      \ \ \____  \ \ \____  \ \  __\   \ \  __ \  \ \  __<   \ \  __\   \ \ \/\ \ 
 \/\_____\    \ \_\  \ \_\ \_\  \ \_____\  \ \_____\     \ \_____\  \ \_____\  \ \_____\  \ \_\ \_\  \ \_\ \_\  \ \_____\  \ \____- 
  \/_____/     \/_/   \/_/\/_/   \/_____/   \/_____/      \/_____/   \/_____/   \/_____/   \/_/\/_/   \/_/ /_/   \/_____/   \/____/ 
                                                                                                                                    

 ______     __  __          __     __   __  
/\  == \   /\ \_\ \        /\ \   /\ \ / /  
\ \  __<   \ \____ \      _\_\ \  \ \ \'/   
 \ \_____\  \/\_____\    /\_____\  \ \_/   
  \/_____/   \/_____/    \/_____/   \//    

                                            
::::::::::::::::::::::::::::::::^^^^^^^^^^^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
::::::..........:::::::::::::::::::^^^^^^^^^^^^^^^^^^^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
...................:::::::::::::::::::^^^^^~~~~!!!777????J7^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
...................:....::::^^^~~!!!77???JJJJJYYYJ7!!~^^^!Y7^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
...............::::.:777????JJ??7???JYYYYYYYYYYYYJ~.^^~^:.~Y7^^^^^^^^^^^~~~~~~~~~~~~~~~~~~~~~~~~~~~~
.........:::::::::...!YJ77?7!J!7~!?!!?JJJJJJYJYYYJJ~~!~^:~.~Y7^^^^^^^^^^^^^^^^^^^^^^^^^~~~~~~~~~~~~~
.......::::::::::.....!YJ!!?!?!7?!7!!777?!7?JJJJJJJJ~~!~:~^.!Y7^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
......::::::::::.......!Y?!7?7J!77!7!!!~!7!77JJJJJJJ?!~~~!!7?JY7^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
......:::::::::.........7Y??7!77!?7??7??????JJJ?!7!!!!!!!!77JJYY7^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
......:::::::::..........7YJJJ?77!7!!!~!~!~7JJJ?777777?777?JJJJJJ7^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
.......:::::::::.........:?YYJ?!!!!777777?JJYYJYYJJJ??!~77777????J!^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
.......::::::::::.........:?YYYJJJ???!!77????JJ?YYYJ?~:~?!7???????7!^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
........::::::::::.........:J55YYJJ?~^77!?????????J?!:^^7?????????7?7:^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
........:::::::::::.........^Y55YJ?~:^??7????????77?7~~!!???JJJJ?7!JP?:^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
........:::::::::::..........~55YJ?~^~!?????????7!7YJJ??Y5PP5YYJ??JPPP?:^^^^^^^^^^^^^^^^^^^^^^^^^^^^
........::::::::::::..........~55J??!!?JYJJJYJ?7!75PPPPPGB###BG55PPPPPP?::^^^^^^^^^^^^^^^^^^^^^^^^^^
.......::::::::::::::...::~~^~^75YJJYYYPB##BP5YYYPGGPPPPPPPPPPPPPPPPPPPP?::^^^^^^^^^^^^^^^^^^^^^^^^^
.......:::::::::::::::.~5~?J?!!~75YYY55PGBBBGPPPGGGPPPPPPP555555PPPPPPPPP?::^^^^^^^^^^^^^^^^^^^^^^^^
......::::::::::::::::::~^5GP7!^:7Y5YYYYYY55PPPGPPPPPPPPPPPP55YJJY5PPPPPPP?:::::^^^^^^^^^^^^^^^^^^^^
.....:::::::::::::::::::.^!~^:::::7YYYYYYYYYYYYY5PPPPPPPPPPP5555YYYYYYYYY5P?:::::::::::^^^^^^^^^^^^^
.....::::::::::::::::::::......::::?YYYYYYYYY?JJY5555555555YYYJJJ????????JY5?::::::::::::::::^^^^^^^
....::::::::::::::::::::::....::::::?YYYYYYYYYJJJ???????JJJJJJJJJJYYYJJJ??JJ5?:::::::::::::::::^^^^^
....:::::::::::::::::::::::..:::::::^J5YJJ???777!7???JJYYYYYJJJJJJJJJJJ????JJY7::^^^^^^^^^^^^^^^^^^^
...::::::::::^^^^^^^^^^^::::.::::::::^Y5YJ!???!^!YYYJJJJJJJJJJJJJJJJJJJ?J???JY5?::^^^^^^^^^^^^^^^^^^
...:::::::::^^^^^^^^^^^^^^^:::::::::::~YP5J7JJ7~^~JJJJJJJJJJJJJJJJJJJJJJ?J???Y5P?::^^^^^^^^^^^^^^^^^
...:::::::::^^^^^^^^^^^^^^^^:::::::^^^:~5P5J7JJ7~^!JJJJJJJJJJJJJJJJJJJJJJ?J??JY5P?:^^^^^^^^^^^^^^^^^
...::::::::::^^^^^^^^^^^^^^^^:::^^^^^^^^!5P5J7JJ7~^!JJJJJJJJJJJJJJJJJJJJJJ???7?J5P?^^^^^^^^^^^^^^^^^
...::::::::::^^^^^^^^^^^^^^^^^^:^^^^^^^^^75P5?7JJ7~^!JJJJJJJJJJJJJJ????????JJYJJY5P?^^^^^^^^^^^^^^^^
..:::::::::::^^^^^^^^^^^^^^^^^^^^^^^^^^^^^7PP5?7JJ7~~!JJJJJ????????JYY55PPPP55YYYY5P?^^^^^^^^^^^^^^^
.::::::::::::^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^?PP5??YJ7~~!7??JYY5PPPPPPPP55555YYYYYYY55PJ^^^^^^^^^^^^^^
::::::::::::^^^^^^^^^^^^^^^^^^^^^^~~~~~~~~~~?P5Y??YJ7!JPGGGPPPPP555555555555555PPPPPPY~^^^^^^^^^^^^^
::::::::::^^^^^^^^^^^^^^^^^^^^^^^^^~~~~~~~~~~J55Y??JJJY55555555555555PPPPPPPPPPPPP5?~^^^^^^^^^^^^^^^
:::::::^^^^^^^^^^^^^^^~~~~~~~~~~~~^^~~~~~~~~~~JYYJ?YYYYYYYY55PPPPPPPPPPPPPPPPPP5J7~^^^^^^^^^^^^^^^^^
::::^^^^^^^^^^^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~!JYJJJJJYYYY55PPPPPPPPPPPPPPP55Y?~^^^^^^^^^^^^^^^^^^^^
^^^^^^^^^^^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~!JYY555PPPPPPPPPPPPPP55YJ?7!~~~^~~~~~~~~~~~~~~~~~~~~~
^^^^^^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~!?5PPPGGGGGPPPP5YJ?77!~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~7JPGGGPPP55YJ?7!!~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
~~~~~~~~~!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!~~!7YPP5YYJ?7!!~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!7??7!!!~~~!!!!!!!!!!!!!!!!!!!!!!~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/


import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


contract stagecleared is ERC1155, ERC1155Supply, Ownable {

    /*//////////////////////////////////////////////////////////////
                            EDITION STRUCT
    //////////////////////////////////////////////////////////////*/

    //define the basis of each edition
    //@param publicPrice being the price per NFT of the public mint
    //@param publicFreeMax being the max per wallet claimable for free
    //@param publicPaidMax being the max per wallet claimable by publicPrice
    //likewise for the whitelist versions
    //@param totalEditionSize being the total size of the edition (inclusive of reservation)
    struct editionBase {
        uint256 publicPrice;
        uint256 publicFreeMax;
        uint256 publicPaidMax;

        uint256 whitelistPrice;
        uint256 whitelistFreeMax;
        uint256 whitelistPaidMax;

        uint256 totalEditionSize;
    }

    /*//////////////////////////////////////////////////////////////
                           DISCOGRAPHY MAPPINGS
    //////////////////////////////////////////////////////////////*/

    //define the discography editions to their respective information structs
    mapping (uint256 => editionBase) public discography;

    /*//////////////////////////////////////////////////////////////
                          EDITION STATE MAPPINGS
    //////////////////////////////////////////////////////////////*/

    //define the whitelist and public state by edition
    mapping (uint256 => bool) public whitelistActive;
    mapping (uint256 => bool) public publicActive;
    
    //define the whitelist and claim index of a current edition
    //@dev discographyWhitelist maps an edition to an address to the bool of if or if not it is whitelisted, a null address, or non whitelisted will return false
    //@dev discographyClaimedTracker maps an edition to an address to teh bool of if or if not the address has claimed the edition already.
    mapping (uint256 => mapping (address => bool)) public discographyWhitelist;

    //@dev edition to user to phase type to quantity
    //@dev quantity maps to 0 = publicFree, 1 = publicPaid, 2 = whitelistFree, 3 = whitelistPaid
    mapping (uint256 => mapping (address => mapping(uint8 => uint256))) userClaimData;

    /*//////////////////////////////////////////////////////////////
                                ERRORS
    //////////////////////////////////////////////////////////////*/

    error incorrectValue();
    error eoaCheckFailed();
    error maxSupplyExceededAfterExecution();
    error amountExceedsLimit(uint256 _amount, uint256 _limit);
    error userMaxClaimsExceeded();
    error notWhitelisted();
    error saleNotLive();

    /*//////////////////////////////////////////////////////////////
                            CURRENT STATE VARIABLES
    //////////////////////////////////////////////////////////////*/

    //global tracker of what the current / active edition is
    uint256 currentEdition;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor (
        string memory _uri
    ) 
        ERC1155(_uri) 
    {}

    /*//////////////////////////////////////////////////////////////
                                CLAIM LOGIC
    //////////////////////////////////////////////////////////////*/

    //@dev Claims a token for the current edition
    //@param msg.value The value sent with the transaction
    function claimToken(uint256 _amount) 
        payable 
        public 
    {

        // Load the edition data into a variable
        editionBase memory currentEditionData = discography[currentEdition];

        // Ensure that tx.origin == msg.sender
        if (tx.origin != msg.sender) revert eoaCheckFailed();

        if (totalSupply(currentEdition) + _amount > currentEditionData.totalEditionSize) revert maxSupplyExceededAfterExecution();

        // Check if whitelistActive for the currentEdition is true
        // Ensure that the mapping for the msg.sender for the currentEdition is false
        if (whitelistActive[currentEdition] && discographyWhitelist[currentEdition][msg.sender]) {

            if (_amount > currentEditionData.whitelistFreeMax + currentEditionData.whitelistPaidMax) revert amountExceedsLimit(_amount, currentEditionData.whitelistFreeMax + currentEditionData.whitelistPaidMax);

            if (userClaimData[currentEdition][msg.sender][2] < currentEditionData.whitelistFreeMax) {

                if (_amount > currentEditionData.whitelistFreeMax) {

                    userClaimData[currentEdition][msg.sender][2] += currentEditionData.whitelistFreeMax;
                    _amount -= currentEditionData.whitelistFreeMax;
                    _mint(msg.sender, currentEdition, currentEditionData.whitelistFreeMax, "");

                } else {

                    userClaimData[currentEdition][msg.sender][2] += _amount;
                    _mint(msg.sender, currentEdition, _amount, "");
                    return;

                }
            }

            if (userClaimData[currentEdition][msg.sender][3] < currentEditionData.whitelistPaidMax) {

                if (_amount == currentEditionData.whitelistPaidMax) {

                    if (msg.value != currentEditionData.whitelistPrice * currentEditionData.whitelistPaidMax) revert incorrectValue();

                    userClaimData[currentEdition][msg.sender][3] += currentEditionData.whitelistPaidMax;
                    _mint(msg.sender, currentEdition, currentEditionData.whitelistPaidMax, "");
                    return;

                } else {

                    if (msg.value != currentEditionData.whitelistPrice * _amount) revert incorrectValue();

                    userClaimData[currentEdition][msg.sender][3] += _amount;
                    _mint(msg.sender, currentEdition, _amount, "");
                    return;

                }
            }

            revert userMaxClaimsExceeded();

        }

        // Check if publicActive for the currentEdition is true
        if (publicActive[currentEdition]) {

            if (_amount > currentEditionData.publicFreeMax + currentEditionData.publicPaidMax) revert amountExceedsLimit(_amount, currentEditionData.publicFreeMax + currentEditionData.publicPaidMax);

            if (userClaimData[currentEdition][msg.sender][0] < currentEditionData.publicFreeMax) {

                if (_amount > currentEditionData.publicFreeMax) {

                    _mint(msg.sender, currentEdition, currentEditionData.publicFreeMax, "");
                    userClaimData[currentEdition][msg.sender][0] += currentEditionData.publicFreeMax;
                    _amount -= currentEditionData.publicFreeMax;

                } else {

                    _mint(msg.sender, currentEdition, _amount, "");
                    userClaimData[currentEdition][msg.sender][0] += _amount;
                    return;

                }
                
            }

            if (userClaimData[currentEdition][msg.sender][1] < currentEditionData.publicPaidMax) {

                if (_amount == currentEditionData.publicPaidMax) {

                    if (msg.value != currentEditionData.publicPrice * currentEditionData.publicPaidMax) revert incorrectValue();

                    
                    userClaimData[currentEdition][msg.sender][1] += currentEditionData.publicPaidMax;
                    _mint(msg.sender, currentEdition, currentEditionData.publicPaidMax, "");
                    return;

                } else {

                    if (msg.value != currentEditionData.publicPrice * _amount) revert incorrectValue();

                    userClaimData[currentEdition][msg.sender][1] += _amount;
                    _mint(msg.sender, currentEdition, _amount, "");
                    return;

                }

            }

            revert userMaxClaimsExceeded();

        }

        revert saleNotLive();
    }

    /*//////////////////////////////////////////////////////////////
                        EDITION MODIFICATION LOGIC
    //////////////////////////////////////////////////////////////*/

    //@dev Updates the values in a struct stored in the discography mapping with the values of the input parameters, using the _edition parameter as the key to access the correct struct in the mapping. 
    //@param _edition The edition to create or modify
    //@param _publicSupply The public supply for this edition
    //@param _publicPrice The public price for this edition
    //@param _whitelistSupply The whitelist supply for this edition
    //@param _whitelistPrice The whitelist price for this edition
    //@param _totalEditionSize The total edition size for this edition
    function createOrModifyEdition(
        uint256 _edition, 

        uint256 _publicPrice, 
        uint256 _publicFreeMax, 
        uint256 _publicPaidMax, 

        uint256 _whitelistPrice,
        uint256 _whitelistFreeMax,
        uint256 _whitelistPaidMax,

        uint256 _totalEditionSize,
        uint256 _reserveAmount
    ) 
        public 
        onlyOwner 
    {
        if (_reserveAmount > _totalEditionSize) revert maxSupplyExceededAfterExecution();

        discography[_edition] = editionBase(_publicPrice, _publicFreeMax, _publicPaidMax, _whitelistPrice, _whitelistFreeMax, _whitelistPaidMax, _totalEditionSize);

        _mint(msg.sender, _edition, _reserveAmount, "");
    }

    //@dev Sets the current edition
    //@param _edition The edition to set as the current edition
    function setCurrentEdition(uint256 _edition) 
        public 
        onlyOwner 
    {
        currentEdition = _edition;
    }

    /*//////////////////////////////////////////////////////////////
                        SALE MODIFICATION LOGIC
    //////////////////////////////////////////////////////////////*/

    //@dev Sets the whitelist active value for the current edition
    //@param _value The value to set for whitelist active
    function setWhitelistLive(bool _value) 
        public 
        onlyOwner 
    {
        whitelistActive[currentEdition] = _value;
    }

    //@dev Sets the public active value for the current edition
    //@param _value The value to set for public active
    function setPublicLive(bool _value)
        public 
        onlyOwner 
    {
        publicActive[currentEdition] = _value;
    }

    //@dev Sets the public active value for the current edition
    //@param _value The value to set for public active
    function setBothPhasesLive(bool _value)
        public 
        onlyOwner 
    {
        publicActive[currentEdition] = _value;
        whitelistActive[currentEdition] = _value;
    }


    /*//////////////////////////////////////////////////////////////
                            WHITELIST LOGIC
    //////////////////////////////////////////////////////////////*/

    //@dev Sets the discography whitelist for the current edition
    //@param _toWhitelist The addresses to whitelist
    //@param _state The state to set for the whitelist
    function setDiscographyWhitelist(address[] memory _toWhitelist, bool _state)
        public 
        onlyOwner 
    {
        for (uint256 i = 0; i < _toWhitelist.length;) {
            discographyWhitelist[currentEdition][_toWhitelist[i]] = _state;
            unchecked { ++i; }
        }
    }

    /*//////////////////////////////////////////////////////////////
                            ADMIN AUX LOGIC
    //////////////////////////////////////////////////////////////*/

    //@dev Allows the owner to admin mint any edition any amount of times incase of reservations or giveaways
    function ownerMint(uint256 _editionType, uint256 _amount) 
        public 
        onlyOwner 
    {
        _mint(msg.sender, _editionType, _amount, "");
    }


    //@dev Allows the owner to withdraw the contract's balance
    function withdraw()
        public 
        onlyOwner 
    {
        payable(msg.sender).transfer(address(this).balance);
    }

    // @dev Calls multiple functions with the provided parameters in a single transaction
    // @param _to The addresses of the functions to call
    // @param _values The values to send with the function calls
    // @param _data The data for each function call
    function multicall(
        address[] memory _to,
        uint256[] memory _values,
        bytes[] memory _data
    )
        public 
        onlyOwner
    {
        // Loop through the provided addresses and call each function
        for (uint256 i = 0; i < _to.length;) {
            // Call the function with the provided parameters
            (bool success, bytes memory returnData) = _to[i].call{ value: _values[i] }(_data[i]);
            require(success, string(returnData));
            unchecked { ++i; }
        }
    }

    /*//////////////////////////////////////////////////////////////
                                URI LOGIC
    //////////////////////////////////////////////////////////////*/

    //@dev Sets the URI for the contract
    //@param newuri The new URI to set for the contract
    function setURI(string memory newuri)
        public 
        onlyOwner 
    {
        _setURI(newuri);
    }

    /// @dev Retrieves the URI for the specified edition
    /// @param _id The ID of the edition to retrieve the URI for
    /// @notice The URI is returned in the format: baseURI + {id} + ".json"
    function uri(uint256 _id) 
        public 
        view 
        override 
        returns (string memory) 
    {
        require(exists(_id), "@dev: Edition does not exist");
        return string(abi.encodePacked(super.uri(_id), Strings.toString(_id), ".json"));
    }

    /*//////////////////////////////////////////////////////////////
                            TRANSFER LOGIC
    //////////////////////////////////////////////////////////////*/

    //@dev Called before a token transfer
    //@param operator The address of the operator calling the function
    //@param from The address the tokens are being transferred from
    //@param to The address the tokens are being transferred to
    //@param ids The ID of the tokens being transferred
    //@param amounts The values of the tokens being transferred
    //@param data Additional data for the transfer
    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        internal
        override(ERC1155, ERC1155Supply)
    {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }
}