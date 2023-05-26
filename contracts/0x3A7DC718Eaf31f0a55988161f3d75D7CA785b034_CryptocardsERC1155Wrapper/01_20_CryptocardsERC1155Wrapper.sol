pragma solidity ^0.8.0;

import "openzeppelin-solidity/contracts/token/ERC1155/IERC1155.sol";
import "openzeppelin-solidity/contracts/token/ERC1155/IERC1155Receiver.sol";
import "openzeppelin-solidity/contracts/security/ReentrancyGuard.sol";
import "./ERC1155Tradable.sol";

interface ERC1155V1Wrapper is IERC1155 {
    function exists(uint256 id) external view returns (bool);
    function totalSupply(uint256 id)  external view returns (uint256);
    function bulkPreBuyCollectible(uint256 _id, uint256[] calldata _printIndexes, uint256 initialPrintPrice) external payable;
}

contract CryptocardsERC1155Wrapper is ERC1155Tradable, ReentrancyGuard, IERC1155Receiver {
    using SafeMath for uint256;

    // Initial ERC1155 wrapper
    address public cardsWrapperV1;

    constructor(address _proxyRegistryAddress, address _erc1155V1Wrapper) ERC1155Tradable("", _proxyRegistryAddress){
        cardsWrapperV1 = _erc1155V1Wrapper;

        // Set the name for display purposes
        name = "Cryptocards";
        // Set the symbol for display purposes
        symbol = "CC";
    }

    function _initialize() override internal {
        setCustomURI(1, "ipfs://QmQMRVoEx7XytHjnaNob6NZWR9wCSTNzZmiGjk7KwMa72c");
        setCustomURI(4, "ipfs://QmdyipWhUjB3fHMcJ3etzkMJBbTxUspCpM7XCWTN4shSCW");
        setCustomURI(6, "ipfs://QmaQ7A8EkgaPuQQnnwY7vTzCVLFpE4NKJ3n62dCbW6wPDs");
        setCustomURI(7, "ipfs://QmbmQZeCC6PWDtMC9SfTHEf1fcYFwbQfLAU1L41Tp3pSGe");
        setCustomURI(8, "ipfs://QmViAYAcnnbeoUwCUDcaKwLAjPTg7h4bLHL9k7429LXBZh");
        setCustomURI(9, "ipfs://Qmd6Tp3oqY2akdhBn1aAS2NeZFbNm9dqcKrvFFAJRG7dsk");
        setCustomURI(10, "ipfs://Qmb1FoWm58HZjh5GCB2aFmhNDCKEK1Cj578YzsBtH7ot41");
        setCustomURI(11, "ipfs://QmSQmKRb6HBNhFZTF53bRQiNBCRugkf8APqq4w3qmXcdP7");
        setCustomURI(12, "ipfs://QmdYdrrwL9Zm51muWyLTVcwd6HqZcokYWauAobvEYQuJDU");
        setCustomURI(13, "ipfs://QmcFLGAHR6VG6iEgaPcSjxfzMnYHk5AKYVePXBEhUg62iS");
        setCustomURI(16, "ipfs://QmfYUR4XqMWFkfZwNd8ftFxztFzLfeXfTU3S5DqxgCFUgv");
        setCustomURI(17, "ipfs://QmTx6sWPqmWiQQzpMVJbJYXz2DPCfsZ5ygHqSUYwgDiYr4");
        setCustomURI(18, "ipfs://QmTquEE43ehwZd814QwJjrBycfJ94y7AmUrKxcC8U9pvk7");
        setCustomURI(19, "ipfs://QmUL5F7WN9Gpws4NYYU1uYezz8FZixZ5a7jvCBnMHdR5gF");
        setCustomURI(20, "ipfs://QmVkyt5T1XJrtuJ5HK1dPPdjHeRc4zCrfMcMpzWR6AtsSD");
        setCustomURI(21, "ipfs://QmXnEHvJwRxf58G26NCtaoavseA9WwMvaWhj6bdkPLRfTN");
        setCustomURI(22, "ipfs://QmSH6TNAkx1XA2WEtyTVC3VuNhRzD9QS8Ky7r4jTgv2UPM");
        setCustomURI(23, "ipfs://Qmbs8AErdJiyjCNLFW4p9xRR9S4jtECADU2mhBXsKePBeV");
        setCustomURI(24, "ipfs://QmXdUiriRH6hRWBj2BJPhVt9nvPtXXwvn8utTMZusSvCgV");
        setCustomURI(25, "ipfs://QmSQJEw6TRKpdqmN5HYmoMQH74xHDTCvx7ELtX8R6J481P");
        setCustomURI(26, "ipfs://QmeQ4b1viDxmsPVxU6NhxiFZdqTGN9qAqR65LkUv25tKiC");
        setCustomURI(27, "ipfs://QmUqdAusa4PEVfN5j9S7S6DUxrEoLsXf61Ct8g79yHPpVQ");
        setCustomURI(28, "ipfs://QmamADMQufmbQB46M7atrZyN82cick74bzhqvLLNd4XW2R");
        setCustomURI(29, "ipfs://QmTrVhVLXmMnuXds3ZSZzKvnuu8Hdb7vkfseqEEjLWgACg");
        setCustomURI(30, "ipfs://QmcytoP4ooabRaN95KbrJQ9eVpGmfRd4hWvZDFFvGgq7CP");
        setCustomURI(31, "ipfs://QmReZLY1F9VotQLfAM7ofTQ5AdXR8B7shaXutX1hCh9qwE");
        setCustomURI(32, "ipfs://QmevHyW2jDoRTN1FDaP57axFEEiXEGPPug853RfwxFuP97");
        setCustomURI(33, "ipfs://QmUFRgGXHf2ju8sixM4MCVis9s1YW61ddiMzrYihKvMdzY");
        setCustomURI(34, "ipfs://QmNheeuRT3Wr9brWJgwYRcRpXx2xcwVwMaYsE26S3TDc9R");
        setCustomURI(35, "ipfs://Qmeq6ZuHqoYQHGmmLPw7Tk88cSKqBqnWV1TYxx7w8MgQ8F");
        setCustomURI(36, "ipfs://QmUEpWo6EKyUvcSVBN9SGLNywuqHjdsNTRgCKbxF5LUu4j");
        setCustomURI(37, "ipfs://QmQaQ2H8y7GJC4fwKJMpoRrZdy1hHVCLcdAYHAKRC2MnWV");
        setCustomURI(38, "ipfs://QmRaxZpmQGW4Sdy9MRw7piENHsjoPTj2sajFTsDMSfib4W");
        setCustomURI(39, "ipfs://QmRsSsG65jcir2A2Weo3VoAUsmv9uiWvfLentxKa7SfYSZ");
        setCustomURI(40, "ipfs://QmSsnEU8g6U1SVf4oZ3UyZNvesLQFHbibHn7sPGp31kGyz");
        setCustomURI(41, "ipfs://QmYrN2RPrJEnjaeqbK47N1FTydQ2xPaeXHcjowYsJEzKMZ");
        setCustomURI(42, "ipfs://QmQUM8sP7PJhhf6sXX4u9UyGyAhpDhFWqG4MQvnDfzUgLr");
        setCustomURI(43, "ipfs://QmRSBsWdfz8VwzEUH1Pwi5VqaQ1mtT9XyzV1MpnH1gbiTv");
        setCustomURI(44, "ipfs://QmQLoQbixDn5iY1TJo4FEJQ3V1zTodoS95MN47Pkp9ngNv");
        setCustomURI(45, "ipfs://QmTCy3gxZMNF7Cnsn9zT6NCNDUSW8Jr5mDGtTVMMmQEzav");
        setCustomURI(46, "ipfs://Qme6tLCFDADrWmZF4TkdtGjj9AncoqwbE5gtP1A7kV1prh");
        setCustomURI(48, "ipfs://QmfJmy9t6pRDFcA25cQSjhnFxex92LPu73wzQjDPuP9sMZ");
        setCustomURI(49, "ipfs://QmeJZoriPwx1sp5xzbYBwjVHVmeepKCp13YgGpi1u4KWuT");
        setCustomURI(50, "ipfs://QmNTfbRLpHknnRNDu1Qaz6qK6Lv92VmhmTBn5VAe1Umyjo");
        setCustomURI(51, "ipfs://QmZ3q8CYwWmoGJmAVChSQ7STrVfx45ZAV55jh7rfjXRncb");
        setCustomURI(53, "ipfs://QmatSm4F4MKStT5h4uYYHJXMTHqttsmKwiCff8mnNeGjBm");
        setCustomURI(54, "ipfs://QmYZZqSaTnWRxZP8dgQDYUVXxjSJBqiPMAm9DYvoWXFWqN");
        setCustomURI(55, "ipfs://QmWwZZQxV1pfTZethyDQ3ywBogiC8HoRWvmAxLAGDwmEkX");
        setCustomURI(56, "ipfs://QmQCiwLE4vJVKvQL8JwRq8x5uiUkXiGC4zjppwrAt2jjpS");
        setCustomURI(57, "ipfs://QmXjaHNNmx7nCqdSrJzJWwUjNyVbgaGmM73TXYtiHUUW2c");
        setCustomURI(58, "ipfs://QmQ2pnZ19iy9CwGQpzqAtQVGhHdaMyqFchqqY2ySAq6Nxy");
        setCustomURI(61, "ipfs://QmYAqRyNKsYWaXHPkfcpPXCMpd1VqsGRZT7keyvSPSNGBT");
        setCustomURI(62, "ipfs://QmPtSsSuNke7mttvBetc1q6dafymCUa9mQW4H9UUoa75NH");
        setCustomURI(63, "ipfs://QmRSyYZbYhzDbBa2bVhLYHePwvwm1mEJw8hMupSdnXfKd4");
        setCustomURI(65, "ipfs://QmbW2T4DNbg8L4xTzCCrAJjsmK4AQywcRTMxYxUAbTQjr3");
        setCustomURI(66, "ipfs://QmVaAk2u5Ci8jX5cb5mMXThAbkC9SA9v68PNybaNqxwvBW");
        setCustomURI(67, "ipfs://QmXevTvmDnm2q7YybhFWqydUnD56sa6uW4fhSmffZXv7oJ");
        setCustomURI(68, "ipfs://QmUYh2aL4RVhbDafXvdLR5wBJWQHrBZqyZkbMQijQZJKTP");
        setCustomURI(69, "ipfs://Qmab2oPjwxtE8xcFX9UNc3StpzUJ1BTx88jcJwFmSnaUcJ");
        setCustomURI(70, "ipfs://QmTMs7dqGFFuZzPetV2B9SpjHTRko1fhsbtdS3z428vcVJ");
        setCustomURI(71, "ipfs://QmaJn7ZTPCqnS7u6YUGjjuLFyBDsEua4YdmL3v1usvvZyj");

    }

    /**
    * @dev Returns the total quantity for a token ID
    * @param _id uint256 ID of the token to query
    * @return amount of token in existence
    */
    function totalSupply(uint256 _id) public view returns (uint256) {
        return ERC1155V1Wrapper(cardsWrapperV1).totalSupply(_id);
    }

    function exists(uint256 _id) external view returns (bool) {
        return ERC1155V1Wrapper(cardsWrapperV1).exists(_id);
    }
    
    /**
        @dev batch version of unwrap.
     */
    function unwrapToERC1155V1Cards(uint256[] calldata _ids, uint256[] calldata _quantities) external nonReentrant {
        require(_ids.length == _quantities.length, "ids and quantities must match");
        _burnBatch(_msgSender(), _ids, _quantities);
        ERC1155V1Wrapper(cardsWrapperV1).safeBatchTransferFrom(address(this), _msgSender(), _ids, _quantities, "");
    }


    /**
        @dev buy bulk Cryptocards from the presale

     */
    function bulkPreBuyCollectible(uint256 _id, uint256[] calldata _printIndexes, uint256 initialPrintPrice) external payable  {
        ERC1155V1Wrapper wrapper = ERC1155V1Wrapper(cardsWrapperV1);
        require(wrapper.exists(_id) == true, "invalid token id");
        wrapper.bulkPreBuyCollectible{value:msg.value}(_id, _printIndexes, initialPrintPrice);
        // mint to user 
        _mint(_msgSender(), _id, _printIndexes.length, "");
    }

    // ============ Callback ============
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata
    ) external override returns (bytes4){
        require(_msgSender() == cardsWrapperV1, "rejected token type");

        // during bulkPreBuyCollectible w1 mints to to current wrapper and we avoid minting here in that scenario 
        if (operator != address(this) && from != address(this)) {
            // mint wrapped tokens
            _mint(from, id, value, "");
        }
        
        return IERC1155Receiver.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata
    ) external override returns (bytes4){
        require(_msgSender() == cardsWrapperV1, "rejected token type");
        require(ids.length == values.length, "PARAMS_NOT_MATCH");

        // during bulkPreBuyCollectible w1 mints to to current wrapper and we avoid minting here in that scenario 
        if (operator != address(this) && from != address(this)) {
            // mint wrapped tokens
            _mintBatch(from, ids, values, "");
        }

        return IERC1155Receiver.onERC1155BatchReceived.selector;
    }
}