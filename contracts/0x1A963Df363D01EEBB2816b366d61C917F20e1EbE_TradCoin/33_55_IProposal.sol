pragma experimental ABIEncoderV2;

//Interface name is not important, however functions in it are important
interface IProposal {
    struct Proposal {
    // proposal id
        uint256 id;
        // title of proposal
        string title;
        // description of proposal
        string desc;
        // the ordered list of target addresses for calls to be made
        address[] targets;
        // the amounts that will be sent by the treasury to each address
        uint256[] values;
        // the denoms that the treasury will send
        string[] signatures;
        // SHOULD BE NULL
        bytes[] calldatas;
    }

    function QueryProp(uint256 propId)
        external
        view
        returns (Proposal memory);
}