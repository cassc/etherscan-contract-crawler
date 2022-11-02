/*
    Copyright 2022 Project Galaxy.
    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
    SPDX-License-Identifier: Apache License, Version 2.0
*/

pragma solidity 0.7.6;

import "./ERC721.sol";
import "./Ownable.sol";
import "./IWPTNFT.sol";
import "./IERC20.sol";

contract WPTNFT is ERC721, IWPTNFT, Ownable {
    using SafeMath for uint256;

    /* ============ Events ============ */
    event EventMinterAdded(address indexed newMinter);
    event EventMinterRemoved(address indexed oldMinter);

    /* ============ Modifiers ============ */
    /**
     * Only minter.
     */

    /* ============ Enums ================ */
    /* ============ Structs ============ */
    /* ============ State Variables ============ */
    // Default allow transfer
    bool public transferable = true;
    bool public enableMint = false;
    address public feeToken = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    uint256 public feeAmount = 358 * 10**6;
    uint256 public performanceFee = 89 * 10**14;
    uint256 public maxSupply = 1000;
    uint256 public maxLimit = 5;
    uint256 public preMintCount = 200;
    address public feeWallet = 0x547ED2Ed1c7b19777dc67cAe4A23d00780a26c36;
    address private teamWallet = 0xeB0d0Fc09a6c360Dc870908108775cD223F3f267;
    address public mintWallet = 0xeB0d0Fc09a6c360Dc870908108775cD223F3f267;
    // Star id to cid.
    mapping(uint256 => bool) public mintedNums;
    mapping(uint256 => uint256) private _cids;
    mapping(address => uint256) public whitelists;

    uint256 private _starCount;
    string private _galaxyName = "Beastie 2D Epic Collection";
    string private _galaxySymbol = "B2D";

    /* ============ Constructor ============ */
    constructor() ERC721("", "") {
        _setBaseURI("ipfs://QmUqEYRgbfV1vjHjpdXp8iACqFZGaYNTdHBHQUNB1LrMni/");
    }

    function preMint(uint256 amount) external {
        require(preMintCount - amount >= 0, "Mint Amount exceed balance");
        require(mintWallet == msg.sender, "Not Allowed Wallet");

        for (uint256 i = 0; i < amount; i++) {
            uint256 r = getRandomMintNum(i);
            _mint(teamWallet, r + 1);
            mintedNums[r] = true;
            _cids[r] = r;
            _starCount++;
        }
        preMintCount = preMintCount.sub(amount);
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override {
        require(transferable, "disabled");
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "caller is not approved or owner"
        );
        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override {
        require(transferable, "disabled");
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "caller is not approved or owner"
        );
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public override {
        require(transferable, "disabled");
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "caller is not approved or owner"
        );
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view override returns (string memory) {
        return _galaxyName;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view override returns (string memory) {
        return _galaxySymbol;
    }

    /**
     * @dev Get Star NFT CID
     */
    function cid(uint256 tokenId) public view returns (uint256) {
        return _cids[tokenId];
    }

    /* ============ External Functions ============ */

    function _transferFee(uint256 amount) internal {
        if (amount > whitelists[msg.sender])
            require(enableMint, "Mint Not Enabled");
        require(msg.value >= performanceFee, "Should pay small gas fee");
        if (msg.value > performanceFee)
            payable(msg.sender).transfer(msg.value - performanceFee);
        payable(feeWallet).transfer(msg.value);

        uint256 _feemintCount;
        if (amount <= whitelists[msg.sender]) {
            _feemintCount = 0;
            whitelists[msg.sender] = whitelists[msg.sender] - amount;
        } else {
            _feemintCount = amount - whitelists[msg.sender];
            whitelists[msg.sender] = 0;
        }
        if (_feemintCount > 0) {
            uint256 _feeAmount = feeAmount.mul(_feemintCount);

            require(
                IERC20(feeToken).balanceOf(msg.sender) >= _feeAmount,
                "Not Enough Fee"
            );

            IERC20(feeToken).transferFrom(
                msg.sender,
                address(this),
                _feeAmount
            );

            uint256 _performanceFee = _feeAmount.mul(35).div(100);
            uint256 _teamFee = _feeAmount.sub(_performanceFee);

            IERC20(feeToken).transfer(feeWallet, _performanceFee);
            IERC20(feeToken).transfer(teamWallet, _teamFee);
        }
    }

    function mint(address account) external payable override returns (uint256) {
        require(_starCount <= maxSupply, "cannot exceed maxSupply");
        require(
            balanceOf(msg.sender) + 1 <= maxLimit,
            "Cannot exceed maxLimit"
        );
        _transferFee(1);
        uint256 r = getRandomMintNum(0);
        mintedNums[r] = true;
        _mint(account, r + 1);
        _cids[r] = r;
        _starCount++;
        return r;
    }

    function mintBatch(address account, uint256 amount)
        external
        payable
        override
        returns (uint256[] memory)
    {
        require(_starCount + amount <= maxSupply, "cannot exceed maxSupply");
        require(
            balanceOf(msg.sender) + amount <= maxLimit,
            "Cannot exceed maxLimit"
        );
        _transferFee(amount);
        uint256[] memory ids = new uint256[](amount);
        for (uint256 i = 0; i < ids.length; i++) {
            uint256 r = getRandomMintNum(i);
            _mint(account, r + 1);
            mintedNums[r] = true;
            _cids[r] = r;
            ids[i] = r;
            _starCount++;
        }
        return ids;
    }

    function burn(address account, uint256 id) external override {
        require(
            _isApprovedOrOwner(_msgSender(), id),
            "caller is not approved or owner"
        );
        _burn(id);
        delete _cids[id];
    }

    function burnBatch(address account, uint256[] calldata ids)
        external
        override
    {
        for (uint256 i = 0; i < ids.length; i++) {
            require(
                _isApprovedOrOwner(_msgSender(), ids[i]),
                "caller is not approved or owner"
            );
            _burn(ids[i]);
            delete _cids[ids[i]];
        }
    }

    /* ============ External Getter Functions ============ */
    function isOwnerOf(address account, uint256 id)
        public
        view
        override
        returns (bool)
    {
        address owner = ownerOf(id);
        return owner == account;
    }

    function getNumMinted() external view override returns (uint256) {
        return _starCount;
    }

    function tokenURI(uint256 id) public view override returns (string memory) {
        require(id <= maxSupply, "NFT does not exist");
        if (bytes(baseURI()).length == 0) {
            return "";
        } else {
            return string(abi.encodePacked(baseURI(), uint2str(id), ".json"));
        }
    }

    /* ============ Internal Functions ============ */
    /* ============ Private Functions ============ */
    /* ============ Util Functions ============ */
    /**
     * PRIVILEGED MODULE FUNCTION. Sets a new baseURI for all token types.
     */

    function setWhiteLists(address[] memory _users, uint256[] memory _amounts)
        external
        onlyOwner
    {
        require(_users.length == _amounts.length, "Not equal length");
        for (uint256 i = 0; i < _users.length; i++) {
            whitelists[_users[i]] = _amounts[i];
        }
    }

    function setURI(string memory newURI) external onlyOwner {
        _setBaseURI(newURI);
    }

    /**
     * PRIVILEGED MODULE FUNCTION. Sets a new transferable for all token types.
     */
    function setTransferable(bool _transferable) external onlyOwner {
        transferable = _transferable;
    }

    function setEnableMint(bool _enable) external onlyOwner {
        enableMint = _enable;
    }

    /**
     * PRIVILEGED MODULE FUNCTION. Sets a new name for all token types.
     */
    function setName(string memory _name) external onlyOwner {
        _galaxyName = _name;
    }

    /**
     * PRIVILEGED MODULE FUNCTION. Sets a new symbol for all token types.
     */
    function setSymbol(string memory _symbol) external onlyOwner {
        _galaxySymbol = _symbol;
    }

    function setFeeWallet(address _newAddress) external onlyOwner {
        feeWallet = _newAddress;
    }

    function setTeamWallet(address _newAddress) external onlyOwner {
        teamWallet = _newAddress;
    }

    function setMintWallet(address _newAddress) external onlyOwner {
        mintWallet = _newAddress;
    }

    function setFeeToken(address _newAddress) external onlyOwner {
        feeToken = _newAddress;
    }

    function setMaxSupply(uint256 _newSupply) external onlyOwner {
        maxSupply = _newSupply;
    }

    function setPerformanceFee(uint256 _newFee) external onlyOwner {
        performanceFee = _newFee;
    }

    function setFeeAmount(uint256 _newFee) external onlyOwner {
        feeAmount = _newFee;
    }

    function setMaxLimit(uint256 _newLimit) external onlyOwner {
        maxLimit = _newLimit;
    }

    function setPreMintCount(uint256 _newCount) external onlyOwner {
        preMintCount = _newCount;
    }

    function uint2str(uint256 _i) internal pure returns (string memory) {
        if (_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bStr = new bytes(len);
        uint256 k = len;
        while (_i != 0) {
            k = k - 1;
            uint8 temp = (48 + uint8(_i - (_i / 10) * 10));
            bytes1 b1 = bytes1(temp);
            bStr[k] = b1;
            _i /= 10;
        }
        return string(bStr);
    }

    function random(uint256 sum) private view returns (uint256) {
        return
            uint256(
                keccak256(
                    abi.encodePacked(
                        block.difficulty,
                        block.timestamp + sum * 1000
                    )
                )
            );
    }

    function getRandomMintNum(uint256 sum) public view returns (uint256) {
        uint256 r = random(sum) % maxSupply;
        if (mintedNums[r]) {
            for (uint256 i = r + 1; i < r + maxSupply; i++)
                if (!mintedNums[i % maxSupply]) return i % maxSupply;
        } else return r;
    }
}