defmodule Gettext.MergerTest do
  use ExUnit.Case, async: true

  alias Gettext.Merger
  alias Gettext.PO
  alias Gettext.PO.Translation

  test "merge/2: headers from the old file are kept" do
    old_po = %PO{headers: [~S(Language: it\n)]}
    new_pot = %PO{headers: ["foo"]}

    assert Merger.merge(old_po, new_pot).headers == old_po.headers
  end

  test "merge/2: obsolete translations are discarded (even the manually entered ones)" do
    old_po = %PO{
      translations: [
        %Translation{msgid: "obs_auto", msgstr: "foo", references: [{"foo.ex", 1}]},
        %Translation{msgid: "obs_manual", msgstr: "foo", references: []},
        %Translation{msgid: "tomerge", msgstr: "foo"},
      ],
    }

    new_pot = %PO{translations: [%Translation{msgid: "tomerge", msgstr: ""}]}

    assert %PO{translations: [t]} = Merger.merge(old_po, new_pot)
    assert %Translation{msgid: "tomerge", msgstr: "foo"} = t
  end

  test "merge/2: when translations match, the msgstr of the old one is preserved" do
    # Note that the msgstr of the new one must be empty as the new one comes
    # from a POT file.

    old_po = %PO{translations: [%Translation{msgid: "foo", msgstr: "bar"}]}
    new_pot = %PO{translations: [%Translation{msgid: "foo", msgstr: ""}]}

    assert %PO{translations: [t]} = Merger.merge(old_po, new_pot)
    assert t.msgstr == "bar"
  end

  test "merge/2: when translations match, existing translator comments are preserved" do
    # Note that the new translation should not have any translator comments
    # (comes from a POT file).

    old_po = %PO{translations: [%Translation{msgid: "foo", comments: ["# existing comment"]}]}
    new_pot = %PO{translations: [%Translation{msgid: "foo", comments: ["# new comment"]}]}

    assert %PO{translations: [t]} = Merger.merge(old_po, new_pot)
    assert t.comments == ["# existing comment"]
  end

  test "merge/2: when translations match, existing references are replaced by new ones" do
    old_po = %PO{translations: [%Translation{msgid: "foo", references: [{"foo.ex", 1}]}]}
    new_pot = %PO{translations: [%Translation{msgid: "foo", references: [{"bar.ex", 1}]}]}

    assert %PO{translations: [t]} = Merger.merge(old_po, new_pot)
    assert t.references == [{"bar.ex", 1}]
  end
end