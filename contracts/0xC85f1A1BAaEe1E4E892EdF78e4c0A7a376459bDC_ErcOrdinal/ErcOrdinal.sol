/**
 *Submitted for verification at Etherscan.io on 2023-03-23
*/

//SPDX-License-Identifier: MIT
//https://ercordinal.io

pragma solidity ^0.8.8;

contract ErcOrdinal {
    uint256 genesis_supply = 111;
    uint256 MAX_SUPPLY = 100000;
    uint256 public mint_price = 10000000000000000;
    uint256 public price_addition = 500000000000000;
    uint8 token_decimals = 0;
    uint256 public token_counter = 0;
    uint256 public free_mint_allocation = 0;
    uint256 public expired_bounty = 0;
    string token_name = "ErcOrdinal";
    string token_symbol = "ERCORD";
    string public base_uri;
    address public the_creator;
    address public ercordinal_erc721;
    mapping(address => mapping(address => uint256)) spender_allowance;
    mapping(uint256 => Tokens) public idToTokens;
    mapping(address => uint256[]) private addressToTokenIds;
    mapping(address => mapping(uint256 => TokenIndex)) private idToTokenIndex;
    mapping(uint256 => EligiblePrize) public idIsEligible;
    mapping(uint256 => EligibleIdForBounty) public idToEligibleForBounty;
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Mint(address indexed _to, uint256 indexed _id);
    event ClaimBounty(uint256 indexed id, uint256 indexed amount);
    event ExpiredBounty(uint256 indexed id);
    event EligibleBounty(
        address indexed minter,
        uint256 indexed id,
        uint256 indexed prize_amount
    );
    event EligibleIds(uint256 indexed id, EligiblePrize eligible_prize);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    /**
     * @dev TokenIndex is needed to track index of ID's inserted.
     * Index started from 1,
     * because every index (even the non-existing one) is default to 0.
     * @notice this index is different from addressToTokenIds
     * which started from 0, normal array
     */
    struct TokenIndex {
        uint256 index;
    }
    struct Tokens {
        address owner;
    }
    /** @dev when all of these ids is_claimed  == true
     *and the rest (the unclaimed one) from_claiming == true
     *free_mint_allocation - expired_bounty should == 0
     */
    struct EligiblePrize {
        bool is_eligible;
        uint256 prize_amount;
        bool is_claimed;
        bool from_claiming;
    }
    struct EligibleIdForBounty {
        bool is_eligible;
        uint256 prize_amount;
    }

    modifier onlyCreator() {
        require(
            msg.sender == the_creator,
            "Only The Creator is Able to Do That"
        );
        _;
    }

    constructor(address _dev1, address _dev2, string memory _base_uri) {
        the_creator = msg.sender;
        genesis(_dev1, _dev2);
        base_uri = _base_uri;
        emit Transfer(address(0), msg.sender, 101);
        emit Transfer(address(0), _dev1, 5);
        emit Transfer(address(0), _dev2, 5);
    }

    function getAddressToIds(
        address _owner
    ) public view returns (uint256[] memory) {
        return addressToTokenIds[_owner];
    }

    function getIdToIndex(
        address _owner,
        uint256 _token_id
    ) public view returns (TokenIndex memory) {
        return idToTokenIndex[_owner][_token_id];
    }

    function getIdToTokens(uint256 _id) public view returns (address) {
        return idToTokens[_id].owner;
    }

    function getGenesisSupply() public view returns (uint256) {
        return genesis_supply;
    }

    // ERC20 standard implementation -->
    function name() public view returns (string memory) {
        return token_name;
    }

    function symbol() public view returns (string memory) {
        return token_symbol;
    }

    function totalSupply() public view returns (uint256) {
        return MAX_SUPPLY;
    }

    function decimals() public view returns (uint256) {
        return token_decimals;
    }

    function balanceOf(address _owner) public view returns (uint256) {
        return addressToTokenIds[_owner].length;
    }

    function transfer(
        address _recipient,
        uint256 _amount
    ) public returns (bool) {
        transferBulk(msg.sender, _recipient, _amount);
        return true;
    }

    function approve(address _spender, uint256 _amount) public returns (bool) {
        spender_allowance[msg.sender][_spender] = _amount;
        emit Approval(msg.sender, _spender, _amount);
        return true;
    }

    function allowance(
        address _owner,
        address _spender
    ) public view returns (uint256) {
        return spender_allowance[_owner][_spender];
    }

    function transferFrom(
        address _sender,
        address _recipient,
        uint256 _amount
    ) public returns (bool) {
        require(
            spender_allowance[_sender][msg.sender] >= _amount,
            "Not enough allowance"
        );
        transferBulk(_sender, _recipient, _amount);
        spender_allowance[_sender][msg.sender] -= _amount;
        return true;
    }

    /** @dev Watch out, idToTokenIndex[address][uint256].index started from 1
     * @param _dev1 and _dev2 assigned initial allocation
     *
     */
    function genesis(address _dev1, address _dev2) private onlyCreator {
        //genesis 0 for the_creator
        idToTokens[0] = Tokens({owner: the_creator});
        addressToTokenIds[the_creator].push(0);
        idToTokenIndex[the_creator][0].index = 1;
        EligiblePrize memory eligible_prize = EligiblePrize({
            is_eligible: true,
            prize_amount: 10,
            is_claimed: false,
            from_claiming: false
        });
        token_counter += 1;
        for (uint256 i = 1; i < genesis_supply; i++) {
            //.index started from 1
            if (i < 6) {
                idToTokens[i] = Tokens({owner: _dev1});
                addressToTokenIds[_dev1].push(i);
                idToTokenIndex[_dev1][i].index = i;
                idIsEligible[i] = eligible_prize;
                emit EligibleIds(i, eligible_prize);
                idToEligibleForBounty[i] = EligibleIdForBounty({
                    is_eligible: true,
                    prize_amount: 10
                });
                token_counter += 1;
            }
            if (i >= 6 && i < 11) {
                idToTokens[i] = Tokens({owner: _dev2});
                addressToTokenIds[_dev2].push(i);
                idToTokenIndex[_dev2][i].index = i - 5;
                idToEligibleForBounty[i] = EligibleIdForBounty({
                    is_eligible: true,
                    prize_amount: 10
                });
                idIsEligible[i] = eligible_prize;
                emit EligibleIds(i, eligible_prize);
                idToEligibleForBounty[i] = EligibleIdForBounty({
                    is_eligible: true,
                    prize_amount: 10
                });
                token_counter += 1;
            }
            if (i >= 11) {
                idToTokens[i] = Tokens({owner: the_creator});
                addressToTokenIds[the_creator].push(i);
                idToTokenIndex[the_creator][i].index = i - 9;
                token_counter += 1;
            }
        }
        free_mint_allocation = 100;
    }

    //set ercordinal erc721 address
    function setErc721Address(address _erc721_address) public onlyCreator {
        ercordinal_erc721 = _erc721_address;
    }

    //set which token ids are eligible for free minting
    function setEligibleIds(
        uint256[] memory _eligible_ids,
        uint256 _amount
    ) public onlyCreator {
        uint256 currentAlloc = token_counter +
            (free_mint_allocation - expired_bounty) +
            (_eligible_ids.length * _amount);
        require(
            currentAlloc < MAX_SUPPLY,
            "Can't set free mint more than max supply"
        );
        for (uint256 i = 0; i < _eligible_ids.length; i++) {
            if (idIsEligible[_eligible_ids[i]].is_eligible == true) {
                //prevent rewriting prize_amount
                revert("Id already inserted");
            }
            if (_eligible_ids[i] + _amount > MAX_SUPPLY - currentAlloc) {
                revert("Can't set free mint more than max supply");
            }
            EligiblePrize memory eligible_prize = EligiblePrize({
                is_eligible: true,
                prize_amount: _amount,
                is_claimed: false,
                from_claiming: false
            });
            idIsEligible[_eligible_ids[i]] = eligible_prize;
            emit EligibleIds(_eligible_ids[i], eligible_prize);
        }
        free_mint_allocation =
            (_eligible_ids.length * _amount) +
            free_mint_allocation;
    }

    //set uniswap resurrect
    ///@notice give free mint eligibility for ids inside uniswap pool
    function setUniswapResurrection(
        uint256[] memory _eligible_ids,
        uint256 _amount
    ) public onlyCreator {
        uint256 currentAlloc = token_counter +
            (free_mint_allocation - expired_bounty) +
            (_eligible_ids.length * _amount);
        require(
            currentAlloc < MAX_SUPPLY,
            "Can't set free mint more than max supply"
        );
        for (uint256 i = 0; i < _eligible_ids.length; i++) {
            if (_eligible_ids[i] + _amount > MAX_SUPPLY - currentAlloc) {
                revert("Can't set free mint more than max supply");
            }
            EligiblePrize memory eligible_prize = EligiblePrize({
                is_eligible: true,
                prize_amount: _amount,
                is_claimed: false,
                from_claiming: false
            });
            idIsEligible[_eligible_ids[i]] = eligible_prize;
            idToEligibleForBounty[_eligible_ids[i]] = EligibleIdForBounty({
                is_eligible: true,
                prize_amount: _amount
            });
            emit EligibleIds(_eligible_ids[i], eligible_prize);
        }
        free_mint_allocation =
            (_eligible_ids.length * _amount) +
            free_mint_allocation;
    }

    //claim free minting
    function claimBounty(uint256 _id) public {
        require(
            idToEligibleForBounty[_id].is_eligible == true,
            "The id is not eligible"
        );
        require(idToTokens[_id].owner == msg.sender, "You are not eligible");

        for (uint256 i = 0; i < idToEligibleForBounty[_id].prize_amount; i++) {
            if (token_counter >= MAX_SUPPLY) {
                revert("Claiming reached max supply");
            }
            uint256 nextId = token_counter + 1;
            if (nextId % 500 == 0) {
                mint_price += price_addition;
            }
            if (idIsEligible[token_counter].is_eligible == true) {
                idIsEligible[token_counter].from_claiming = true;
                expired_bounty += idIsEligible[token_counter].prize_amount;
                emit ExpiredBounty(token_counter);
            }
            idToTokens[token_counter] = Tokens({owner: msg.sender});
            idToTokenIndex[msg.sender][token_counter].index =
                addressToTokenIds[msg.sender].length +
                1;
            addressToTokenIds[msg.sender].push(token_counter);
            token_counter += 1;
            emit Mint(msg.sender, token_counter);
        }
        idIsEligible[_id].is_claimed = true;
        free_mint_allocation -= idToEligibleForBounty[_id].prize_amount;
        delete idToEligibleForBounty[_id];
        emit ClaimBounty(_id, idToEligibleForBounty[_id].prize_amount);
        emit Transfer(
            address(0),
            msg.sender,
            idToEligibleForBounty[_id].prize_amount
        );
    }

    //claim free minting via erc721
    function claimViaErc721(uint256 _id, address _owner) external {
        require(
            msg.sender == ercordinal_erc721,
            "Only ErcOrdinal ERC721 address can call"
        );
        if (token_counter >= MAX_SUPPLY) {
            revert("Claiming reached max supply");
        }
        require(
            idToEligibleForBounty[_id].is_eligible == true,
            "The id is not eligible"
        );
        require(idToTokens[_id].owner == _owner, "You are not eligible");
        for (uint256 i = 0; i < idToEligibleForBounty[_id].prize_amount; i++) {
            uint256 nextId = token_counter + 1;
            if (nextId % 500 == 0) {
                mint_price += price_addition;
            }
            if (idIsEligible[token_counter].is_eligible == true) {
                idIsEligible[token_counter].from_claiming = true;
                expired_bounty += idIsEligible[token_counter].prize_amount;
                emit ExpiredBounty(token_counter);
            }
            idToTokens[token_counter] = Tokens({owner: _owner});
            idToTokenIndex[_owner][token_counter].index =
                addressToTokenIds[_owner].length +
                1;
            addressToTokenIds[_owner].push(token_counter);
            token_counter += 1;
            emit Mint(_owner, token_counter);
        }
        idIsEligible[_id].is_claimed = true;
        free_mint_allocation -= idToEligibleForBounty[_id].prize_amount;
        delete idToEligibleForBounty[_id];
        emit ClaimBounty(_id, idToEligibleForBounty[_id].prize_amount);
        emit Transfer(
            address(0),
            _owner,
            idToEligibleForBounty[_id].prize_amount
        );
    }

    function mintMany(uint256 _amount) external payable {
        uint256 token_left = free_mint_allocation - expired_bounty;
        require(token_counter < MAX_SUPPLY - token_left, "Max supply reached");
        if (token_counter + _amount > MAX_SUPPLY - token_left) {
            revert("Can't mint more than max supply");
        }
        require(msg.value >= mint_price * _amount, "Not enough ETH");
        require(_amount > 0, "Can't mint zero amount");
        for (uint256 i = 0; i < _amount; i++) {
            uint256 modder = token_counter;
            uint256 nextId = token_counter + 1;
            //revert if there's id in mintMany located beetwen old and new price
            if (modder % 500 == 0 && i != 0) {
                revert("Hit price change point");
            }
            if (msg.value < mint_price * _amount) {
                revert("Price already up");
            }
            if (nextId % 500 == 0) {
                mint_price += price_addition;
            }
            //add token id to winners list
            if (idIsEligible[token_counter].is_eligible == true) {
                idToEligibleForBounty[token_counter] = EligibleIdForBounty({
                    is_eligible: true,
                    prize_amount: idIsEligible[token_counter].prize_amount
                });
                emit EligibleBounty(
                    msg.sender,
                    token_counter,
                    idIsEligible[token_counter].prize_amount
                );
            }
            idToTokens[token_counter] = Tokens({owner: msg.sender});
            idToTokenIndex[msg.sender][token_counter].index =
                addressToTokenIds[msg.sender].length +
                1;
            addressToTokenIds[msg.sender].push(token_counter);
            token_counter += 1;
            emit Mint(msg.sender, token_counter);
        }
        emit Transfer(address(0), msg.sender, _amount);
    }

    function withdrawMintSale() public onlyCreator {
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(success, "failed");
    }

    ///@dev read this one carefully, easy to get lost in it ^_^
    function transferBulk(
        address _sender,
        address _recipient,
        uint256 _amount
    ) private {
        require(
            _amount <= addressToTokenIds[_sender].length,
            "Not enough balance"
        );
        require(_sender != _recipient, "Self transfer not allowed");
        require(_sender != address(0), "ERC20: transfer from the zero address");
        uint256 senderHoldingsLength = addressToTokenIds[_sender].length;
        uint256 recipientLength = addressToTokenIds[_recipient].length;
        if (recipientLength < 1) {
            for (uint256 i = 1; i < _amount + 1; i++) {
                uint256 senderLastTokenIndex = senderHoldingsLength - i;
                uint256 senderLastTokenId = addressToTokenIds[_sender][
                    senderLastTokenIndex
                ];
                idToTokenIndex[_recipient][senderLastTokenId].index = i;
                addressToTokenIds[_recipient].push(senderLastTokenId);
                //change the tokens owner
                idToTokens[senderLastTokenId].owner = _recipient;
                //take out ids, no need to know the ids
                addressToTokenIds[_sender].pop();
                delete idToTokenIndex[_sender][senderLastTokenId];
            }

            emit Transfer(_sender, _recipient, _amount);
        } else {
            for (uint256 i = 1; i < _amount + 1; i++) {
                uint256 senderLastTokenIndex = senderHoldingsLength - i;
                uint256 senderLastTokenId = addressToTokenIds[_sender][
                    senderLastTokenIndex
                ];
                uint256 idToMove = addressToTokenIds[_recipient][i - 1];
                //add ids, this needs ids instead
                idToTokenIndex[_recipient][idToMove].index =
                    recipientLength +
                    i;
                addressToTokenIds[_recipient].push(idToMove);
                idToTokenIndex[_recipient][senderLastTokenId].index = i;
                addressToTokenIds[_recipient][i - 1] = senderLastTokenId;
                //change the tokens owner
                idToTokens[senderLastTokenId].owner = _recipient;
                //take out ids, no need to know the ids
                addressToTokenIds[_sender].pop();
                delete idToTokenIndex[_sender][senderLastTokenId];
            }
            emit Transfer(_sender, _recipient, _amount);
        }
    }

    function transferMany(address _recipient, uint256[] memory _ids) public {
        require(_recipient != msg.sender, "Self transfer not allowed");
        require(
            _ids.length <= addressToTokenIds[msg.sender].length,
            "Not enough balance"
        );
        for (uint256 i = 0; i < _ids.length; i++) {
            transferSingle(_recipient, _ids[i]);
        }
        emit Transfer(msg.sender, _recipient, _ids.length);
    }

    function transferSingle(address _recipient, uint256 _id) private {
        require(_recipient != msg.sender, "Self transfer not allowed");
        require(idToTokens[_id].owner == msg.sender, "Must be the owner");
        uint256 senderLastIndex = addressToTokenIds[msg.sender].length - 1;
        uint256 senderLastId = addressToTokenIds[msg.sender][senderLastIndex];
        //_id won't be duplicate
        //once sent, ownership changed
        idToTokenIndex[_recipient][_id].index =
            addressToTokenIds[_recipient].length +
            1;
        addressToTokenIds[_recipient].push(_id);
        //change the owner
        idToTokens[_id].owner = _recipient;
        //find the index position of _id
        uint256 indexToRemove = idToTokenIndex[msg.sender][_id].index;
        //move last id on the arrays
        uint256 idToMove = addressToTokenIds[msg.sender][senderLastIndex];
        addressToTokenIds[msg.sender][indexToRemove - 1] = idToMove;
        //update idTotokenIndex for sender
        idToTokenIndex[msg.sender][senderLastId].index = indexToRemove;
        delete idToTokenIndex[msg.sender][_id];
        addressToTokenIds[msg.sender].pop();
    }

    function erc721Switch(address _from, uint256 _id) public {
        require(
            msg.sender == ercordinal_erc721,
            "Only ErcOrdinal ERC721 address can call"
        );
        require(
            idToTokens[_id].owner == _from,
            "Address from is not the owner"
        );
        uint256 senderLastIndex = addressToTokenIds[_from].length - 1;
        uint256 senderLastId = addressToTokenIds[_from][senderLastIndex];
        idToTokenIndex[msg.sender][_id].index =
            addressToTokenIds[msg.sender].length +
            1;
        addressToTokenIds[msg.sender].push(_id);
        idToTokens[_id].owner = msg.sender;
        //find the index position of _id
        uint256 indexToRemove = idToTokenIndex[_from][_id].index;
        //move last id on the arrays
        uint256 idToMove = addressToTokenIds[_from][senderLastIndex];
        addressToTokenIds[_from][indexToRemove - 1] = idToMove;
        //update idTotokenIndex for sender
        idToTokenIndex[_from][senderLastId].index = indexToRemove;
        delete idToTokenIndex[_from][_id];
        addressToTokenIds[_from].pop();
        emit Transfer(_from, msg.sender, 1);
    }
}