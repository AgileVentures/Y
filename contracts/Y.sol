pragma solidity 0.4.19; // TODO update?

contract Y {
    address payee;
    Proportion public donationProportion;
    struct Proportion {
        uint num; // numerator
        uint denom; // denominator
    } // e.g. 25% (0.25) is represented as Proportion(25, 100)

    function Y(uint num, uint denom) public {
        require(0 < num && num < denom); // 0 < num/denom < 100%
        donationProportion = Proportion(num, denom);
        payee = msg.sender;
    }

    function payAndDonate(uint num, uint denom, address donee) public payable { // TODO Is returning bool necessary?
        require(num == donationProportion.num && denom == donationProportion.denom);
        require((msg.value * donationProportion.num) / msg.value == donationProportion.num); // OpenZeppelin
        uint donation = (msg.value * donationProportion.num) / donationProportion.denom;
        payee.transfer(msg.value - donation); // won't underflow, donation always <= msg.value
        donee.transfer(donation);
    }

    function setDonationProportion(uint num, uint denom) public {
        require(0 < num && num < denom); // 0 < num/denom < 100%
        require(msg.sender == payee);
        donationProportion = Proportion(num, denom);
    }
}
