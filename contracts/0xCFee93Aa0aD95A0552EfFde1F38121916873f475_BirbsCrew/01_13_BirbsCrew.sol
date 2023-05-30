// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "./interfaces/IMoonbirds.sol";
import "./interfaces/IProof.sol";

contract BirbsCrew is ERC721, Ownable {
    //MAINNET ADDRESSES
    address public developer = address(0x7c5252031d236d5A17db832Fc8367e6850a3b4FB);
    address public openSeaProxy = address(0xa5409ec958C83C3f309868babACA7c86DCB077c1);
    IMoonbirds public moonbirds = IMoonbirds(0x23581767a106ae21c074b2276D25e5C3e136a68b);
    IProof public proof = IProof(0x08D7C0242953446436F34b4C78Fe9da38c73668d);

    string public uri;
    uint256 public minted;

    uint256 public MOONBIRD_EARLY_PRICE = 0.05 ether;
    //July 22, 2022 11:00:00 EDT
    uint256 public MOONBIRD_EARLY_START_TIME = 1658502000;
    uint256 public MOONBIRD_EARLY_DURATION = 24 hours;

    uint256 public MOONBIRD_PRICE = 0.07 ether;
    uint256 public MOONBIRD_START_TIME =
        MOONBIRD_EARLY_START_TIME + MOONBIRD_EARLY_DURATION;
    uint256 public MOONBIRD_DURATION = 7 days;

    uint256 public PUBLIC_PRICE = 0.1 ether;
    uint256 public PUBLIC_START_TIME = MOONBIRD_START_TIME + MOONBIRD_DURATION;

    mapping(uint256 => bool) public proofClaimed;

    constructor(
        string memory _uri
    ) ERC721("Birbs Crew", "BIRB") {
        uri = _uri;
    }

    function totalSupply() external view returns (uint256) {
        return minted;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        return
            string(abi.encodePacked(uri, Strings.toString(tokenId), ".json"));
    }

    function setPublicStartTime(uint256 _publicStartTime) external onlyOwner {
        PUBLIC_START_TIME = _publicStartTime;
    }

    function setPublicPrice(uint256 _publicPrice) external onlyOwner {
        PUBLIC_PRICE = _publicPrice;
    }

    function setMoonbirdEarlyStartTime(uint256 _moonbirdEarlyStartTime)
        external
        onlyOwner
    {
        MOONBIRD_EARLY_START_TIME = _moonbirdEarlyStartTime;
    }

    function setMoonbirdEarlyPrice(uint256 _moonbirdEarlyPrice)
        external
        onlyOwner
    {
        MOONBIRD_EARLY_PRICE = _moonbirdEarlyPrice;
    }

    function setMoonbirdEarlyDuration(uint256 _moonbirdEarlyDuration)
        external
        onlyOwner
    {
        MOONBIRD_EARLY_DURATION = _moonbirdEarlyDuration;
    }

    function setMoonbirdStartTime(uint256 _moonbirdStartTime)
        external
        onlyOwner
    {
        MOONBIRD_START_TIME = _moonbirdStartTime;
    }

    function setMoonbirdPrice(uint256 _moonbirdPrice) external onlyOwner {
        MOONBIRD_PRICE = _moonbirdPrice;
    }

    function setMoonbirdDuration(uint256 _moonbirdDuration) external onlyOwner {
        MOONBIRD_DURATION = _moonbirdDuration;
    }

    function setURI(string memory _uri) public onlyOwner {
        uri = _uri;
    }

    function mint(uint256[] calldata moonbirdIds, address sender) internal {
        require(
            block.timestamp > MOONBIRD_EARLY_START_TIME,
            "Minting has not started yet."
        );

        require(moonbirdIds.length > 0, "No moonbirds to mint");

        for (uint256 i = 0; i < moonbirdIds.length; i++) {
            require(
                moonbirds.ownerOf(moonbirdIds[i]) == sender,
                "You do not own this Moonbird"
            );

            minted += 1;
            _safeMint(sender, moonbirdIds[i]);
        }
    }

    function claimProof(address sender, uint256 proofId) internal {
        require(proof.ownerOf(proofId) == sender, "You do not own this proof");
        proofClaimed[proofId] = true;
    }

    function mintMoonbird(
        uint256[] calldata moonbirdIds,
        uint256[] calldata proofIds
    ) external payable {
        require(block.timestamp < PUBLIC_START_TIME, "Minting has ended");
        uint256 amount = moonbirdIds.length;
        uint256 proofBalance = proofIds.length;

        for (uint256 i = 0; i < proofIds.length; i++) {
            if (proofClaimed[proofIds[i]]) {
                proofBalance -= 1;
            } else {
                claimProof(msg.sender, proofIds[i]);
            }
        }

        //Prevent integer underflow
        if (amount > proofBalance) {
            if (block.timestamp < MOONBIRD_START_TIME) {
                require(
                    msg.value >= MOONBIRD_EARLY_PRICE * (amount - proofBalance),
                    "Not enough ether sent (early)"
                );
            } else if (block.timestamp < PUBLIC_START_TIME) {
                require(
                    msg.value >= MOONBIRD_PRICE * (amount - proofBalance),
                    "Not enough ether sent"
                );
            }
        }

        mint(moonbirdIds, msg.sender);
    }

    function verifyString(
        string memory message,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public pure returns (address signer) {
        // The message header; we will fill in the length next
        string memory header = "\x19Ethereum Signed Message:\n000000";

        uint256 lengthOffset;
        uint256 length;
        assembly {
            // The first word of a string is its length
            length := mload(message)
            // The beginning of the base-10 message length in the prefix
            lengthOffset := add(header, 57)
        }

        // Maximum length we support
        require(length <= 999999);

        // The length of the message's length in base-10
        uint256 lengthLength = 0;

        // The divisor to get the next left-most message length digit
        uint256 divisor = 100000;

        // Move one digit of the message length to the right at a time
        while (divisor != 0) {
            // The place value at the divisor
            uint256 digit = length / divisor;
            if (digit == 0) {
                // Skip leading zeros
                if (lengthLength == 0) {
                    divisor /= 10;
                    continue;
                }
            }

            // Found a non-zero digit or non-leading zero digit
            lengthLength++;

            // Remove this digit from the message length's current value
            length -= digit * divisor;

            // Shift our base-10 divisor over
            divisor /= 10;

            // Convert the digit to its ASCII representation (man ascii)
            digit += 0x30;
            // Move to the next character and write the digit
            lengthOffset++;

            assembly {
                mstore8(lengthOffset, digit)
            }
        }

        // The null string requires exactly 1 zero (unskip 1 leading 0)
        if (lengthLength == 0) {
            lengthLength = 1 + 0x19 + 1;
        } else {
            lengthLength += 1 + 0x19;
        }

        // Truncate the tailing zeros from the header
        assembly {
            mstore(header, lengthLength)
        }

        // Perform the elliptic curve recover operation
        bytes32 check = keccak256(abi.encodePacked(header, message));

        return ecrecover(check, v, r, s);
    }

    function mintVault(
        uint256[] calldata moonbirdIds,
        uint256[] calldata proofIds,
        address _vaultAddress,
        string memory _msg,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external payable {
        require(block.timestamp < PUBLIC_START_TIME, "Minting has ended");

        require(
            _vaultAddress == verifyString(_msg, _v, _r, _s),
            "You do not own this vault"
        );

        uint256 amount = moonbirdIds.length;
        uint256 proofBalance = proofIds.length;

        for (uint256 i = 0; i < proofIds.length; i++) {
            if (proofClaimed[proofIds[i]]) {
                proofBalance -= 1;
            } else {
                claimProof(_vaultAddress, proofIds[i]);
            }
        }

        //Prevent integer underflow
        if (amount > proofBalance) {
            if (block.timestamp < MOONBIRD_START_TIME) {
                require(
                    msg.value >= MOONBIRD_EARLY_PRICE * (amount - proofBalance),
                    "Not enough ether sent"
                );
            } else {
                require(
                    msg.value >= MOONBIRD_PRICE * (amount - proofBalance),
                    "Not enough ether sent"
                );
            }
        }

        mint(moonbirdIds, _vaultAddress);
    }

    function mintPublic(uint256 tokenId) external payable {
        require(
            block.timestamp > PUBLIC_START_TIME,
            "Minting has not started yet"
        );
        require(msg.value >= PUBLIC_PRICE);

        _safeMint(msg.sender, tokenId);

        minted += 1;
    }

    function mint(uint256 tokenId) external onlyOwner {
        _safeMint(msg.sender, tokenId);

        minted += 1;
    }

    function withdraw() external onlyOwner {
        uint256 rate = 6250;

        if (minted <= 1000) {
            rate = 12500;
        } else if (minted <= 2500) {
            rate = 10625;
        } else if (minted <= 5000) {
            rate = 9375;
        } else if (minted <= 7500) {
            rate = 8125;
        }

        (bool success, ) = developer.call{
            value: (address(this).balance * rate) / 100000
        }("");
        require(success, "Could not send ether to developer");

        (success, ) = owner().call{value: address(this).balance}("");
        require(success, "Could not send ether to owner");
    }

    function isApprovedForAll(address _owner, address operator)
        public
        view
        override
        returns (bool)
    {
        OpenSeaProxyRegistry proxyRegistry = OpenSeaProxyRegistry(openSeaProxy);
        if (address(proxyRegistry.proxies(_owner)) == operator) return true;
        return super.isApprovedForAll(_owner, operator);
    }
}

contract OwnableDelegateProxy {}

contract OpenSeaProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}